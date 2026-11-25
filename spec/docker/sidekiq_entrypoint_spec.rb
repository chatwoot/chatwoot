require 'spec_helper'
require 'fileutils'
require 'open3'
require 'tmpdir'

# The worker waits for the schema, and HOW it waits is load-bearing: `rake
# db:abort_if_pending_migrations` boots a db: task, and booting one against an empty database
# creates ar_internal_metadata and schema_migrations. `db:chatwoot_prepare` reads
# `table_exists? 'ar_internal_metadata'` to decide whether the database is fresh, so a worker
# that asked first made the web container skip the schema load and migrate from InitSchema,
# which dies on 20231211010807_add_cached_labels_list. The fix is to reach the rake only after
# the schema exists, and that ordering is what these examples hold.
#
# Run against stubs, in a temporary directory shaped like the app: what is under test is the
# order of the questions, not postgres or Rails.
# rubocop:disable RSpec/DescribeClass -- the subject is a shell script, not a constant
RSpec.describe 'docker/entrypoints/sidekiq.sh', type: :script do
  let(:app_dir) { Dir.mktmpdir }
  let(:bin_dir) { File.join(app_dir, 'bin') }
  let(:calls_file) { File.join(app_dir, 'calls') }
  # how many `rails runner` calls fail before the schema shows up, and how many `rake` calls
  # fail before the migrations are current; a test writes them before running the gate
  let(:schema_after) { File.join(app_dir, 'schema_after') }
  let(:migrations_after) { File.join(app_dir, 'migrations_after') }

  before do
    FileUtils.mkdir_p([File.join(app_dir, 'docker/entrypoints/helpers'), bin_dir])

    gate = File.join(app_dir, 'docker/entrypoints/sidekiq.sh')
    FileUtils.cp(File.expand_path('../../docker/entrypoints/sidekiq.sh', __dir__), gate)
    FileUtils.chmod(0o755, gate)

    # the helper only exports connection params; an empty one keeps the gate honest
    helper = File.join(app_dir, 'docker/entrypoints/helpers/pg_database_url.rb')
    File.write(helper, "#!/usr/bin/env ruby\n")
    FileUtils.chmod(0o755, helper)

    # the embedded connector's supervisor, which takes the worker command over when it runs
    supervisor = File.join(app_dir, 'docker/entrypoints/helpers/whatsapp_connector.rb')
    File.write(supervisor, "#!/bin/sh\necho \"supervise $*\" >> \"#{calls_file}\"\n")
    FileUtils.chmod(0o755, supervisor)

    enterprise = File.join(app_dir, 'docker/entrypoints/helpers/enterprise.sh')
    File.write(enterprise, "#!/bin/sh\necho \"enterprise $*\" >> \"#{calls_file}\"\nexit \"${ENTERPRISE_STUB_STATUS:-0}\"\n")
    FileUtils.chmod(0o755, enterprise)

    stub('pg_isready', "exit 0\n")
    stub('sleep', "exit 0\n")
    stub('bundle', <<~SH)
      echo "$*" >> "#{calls_file}"
      case "$*" in
        *"rails runner"*)
          n=$(grep -c "rails runner" "#{calls_file}")
          [ "$n" -ge "$(cat "#{schema_after}")" ] && exit 0 || exit 1
          ;;
        *"db:abort_if_pending_migrations"*)
          n=$(grep -c "db:abort_if_pending_migrations" "#{calls_file}")
          [ "$n" -ge "$(cat "#{migrations_after}")" ] && exit 0 || exit 1
          ;;
      esac
      exit 0
    SH
    File.write(schema_after, '1')
    File.write(migrations_after, '1')
  end

  after { FileUtils.remove_entry(app_dir) }

  def stub(name, body)
    path = File.join(bin_dir, name)
    File.write(path, "#!/bin/sh\n#{body}")
    FileUtils.chmod(0o755, path)
  end

  def run(env = {})
    Open3.capture3({ 'PATH' => "#{bin_dir}:#{ENV.fetch('PATH')}", 'WHATSAPP_CONNECTOR_ENABLED' => nil,
                     'WHATSAPP_CONNECTOR_EMBEDDED' => nil }.merge(env),
                   'docker/entrypoints/sidekiq.sh', 'bundle', 'exec', 'sidekiq', '-C', 'config/sidekiq.yml',
                   chdir: app_dir)
  end

  def calls
    File.readlines(calls_file, chomp: true)
  end

  it 'ensures enterprise/ before it asks Rails anything' do
    run

    expect(calls.first).to eq('enterprise ensure')
  end

  it 'does not start the worker when enterprise/ cannot be ensured' do
    _out, _err, status = run('ENTERPRISE_STUB_STATUS' => '1')

    expect(status).not_to be_success
    expect(calls).to eq(['enterprise ensure'])
  end

  it 'does not ask the rake anything while the schema is missing' do
    File.write(schema_after, '3')

    run

    # the rake creates tables on an empty database; nothing may reach it before the schema is there
    first_rake = calls.index { |c| c.include?('db:abort_if_pending_migrations') }
    expect(calls.first(first_rake).count { |c| c.include?('rails runner') }).to eq(3)
    expect(calls.count { |c| c.include?('db:abort_if_pending_migrations') }).to eq(1)
  end

  it 'keeps waiting on the rake while migrations are pending' do
    File.write(migrations_after, '3')

    run

    expect(calls.count { |c| c.include?('db:abort_if_pending_migrations') }).to eq(3)
  end

  it 'execs the worker once the schema is current' do
    out, _err, status = run('WHATSAPP_CONNECTOR_ENABLED' => 'false')

    expect(status).to be_success
    expect(out).to include('Schema is current. Starting the worker.')
    expect(calls.last).to eq('exec sidekiq -C config/sidekiq.yml')
  end

  it 'hands the worker to the connector supervisor when the connector is enabled' do
    run('WHATSAPP_CONNECTOR_ENABLED' => 'true')

    expect(calls.last).to eq('supervise bundle exec sidekiq -C config/sidekiq.yml')
  end

  it 'runs the worker alone when the connector is a separate service' do
    run('WHATSAPP_CONNECTOR_ENABLED' => 'true', 'WHATSAPP_CONNECTOR_EMBEDDED' => 'false')

    expect(calls.last).to eq('exec sidekiq -C config/sidekiq.yml')
  end

  it 'hands the worker to the supervisor when nothing says whether the connector is enabled' do
    run

    expect(calls.last).to eq('supervise bundle exec sidekiq -C config/sidekiq.yml')
  end

  it 'runs the worker alone when the connector is turned off' do
    run('WHATSAPP_CONNECTOR_ENABLED' => 'false', 'WHATSAPP_CONNECTOR_EMBEDDED' => 'true')

    expect(calls.last).to eq('exec sidekiq -C config/sidekiq.yml')
  end
end
# rubocop:enable RSpec/DescribeClass
