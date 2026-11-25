require 'spec_helper'
require 'fileutils'
require 'open3'
require 'tmpdir'

# The web entrypoint runs db:chatwoot_prepare, which boots Rails, and Rails decides whether
# this is an Enterprise installation by whether enterprise/ exists. So the tree has to be in
# place before the first rake, and a container that could not get it must not migrate or
# serve. Run against stubs, in a temporary directory shaped like the app.
# rubocop:disable RSpec/DescribeClass -- the subject is a shell script, not a constant
RSpec.describe 'docker/entrypoints/rails.sh', type: :script do
  let(:app_dir) { Dir.mktmpdir }
  let(:bin_dir) { File.join(app_dir, 'bin') }
  let(:calls_file) { File.join(app_dir, 'calls') }

  before do
    FileUtils.mkdir_p([File.join(app_dir, 'docker/entrypoints/helpers'), bin_dir])

    entrypoint = File.join(app_dir, 'docker/entrypoints/rails.sh')
    FileUtils.cp(File.expand_path('../../docker/entrypoints/rails.sh', __dir__), entrypoint)
    FileUtils.chmod(0o755, entrypoint)

    { 'pg_database_url.rb' => "#!/bin/sh\n",
      'enterprise.sh' => "#!/bin/sh\necho \"enterprise $*\" >> \"#{calls_file}\"\nexit \"${ENTERPRISE_STUB_STATUS:-0}\"\n" }.each do |name, body|
      path = File.join(app_dir, 'docker/entrypoints/helpers', name)
      File.write(path, body)
      FileUtils.chmod(0o755, path)
    end

    { 'pg_isready' => "exit 0\n", 'bundle' => "echo \"bundle $*\" >> \"#{calls_file}\"\n" }.each do |name, body|
      path = File.join(bin_dir, name)
      File.write(path, "#!/bin/sh\n#{body}")
      FileUtils.chmod(0o755, path)
    end
  end

  after { FileUtils.remove_entry(app_dir) }

  def run(env = {})
    Open3.capture3({ 'PATH' => "#{bin_dir}:#{ENV.fetch('PATH')}" }.merge(env),
                   'docker/entrypoints/rails.sh', 'echo', 'server', chdir: app_dir)
  end

  def calls
    File.readlines(calls_file, chomp: true)
  end

  it 'ensures enterprise/ before the database is prepared' do
    out, _err, status = run

    expect(status).to be_success
    expect(calls.first).to eq('enterprise ensure')
    expect(calls).to include('bundle exec rake db:chatwoot_prepare')
    expect(out).to include('server')
  end

  it 'neither migrates nor serves when enterprise/ cannot be ensured' do
    out, _err, status = run('ENTERPRISE_STUB_STATUS' => '1')

    expect(status).not_to be_success
    expect(calls).to eq(['enterprise ensure'])
    expect(out).not_to include('server')
  end
end
# rubocop:enable RSpec/DescribeClass
