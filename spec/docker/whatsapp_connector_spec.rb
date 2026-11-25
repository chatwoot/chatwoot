require 'spec_helper'
require 'fileutils'
require 'open3'
require 'redis'
require 'securerandom'
require 'socket'
require 'timeout'
require 'tmpdir'
require_relative '../../docker/entrypoints/helpers/whatsapp_connector'

# The connector runs inside the Sidekiq container, and the order of who stops whom is the
# part that can lose something: a connector killed without SIGTERM keeps its session leases
# until they run out, and a worker taken down by a connector crash is a WhatsApp outage
# turned into a Chatwoot outage. The supervisor runs here against stub processes, which
# record what happened to them in files.
# rubocop:disable RSpec/DescribeClass -- the subject is the script, run as the image runs it
RSpec.describe 'docker/entrypoints/helpers/whatsapp_connector.rb', type: :script do
  let(:dir) { Dir.mktmpdir }
  let(:bin_dir) { File.join(dir, 'bin') }
  let(:script) { File.expand_path('../../docker/entrypoints/helpers/whatsapp_connector.rb', __dir__) }
  let(:supervisors) { [] }
  let(:outputs) { [] }

  before do
    FileUtils.mkdir_p(bin_dir)
    # Records each start with the environment it got, and each SIGTERM; exits when told to
    # through a file, so a test can crash it on purpose.
    stub('whatsapp-connector', <<~SH)
      echo "start $$ $WAC_ENGINE $WAC_DATABASE_URL $WAC_MEDIA_ROOT $WAC_MEDIA_TOKEN" >> "#{dir}/connector"
      trap 'echo "term $$" >> "#{dir}/connector"; exit 0' TERM
      while [ ! -f "#{dir}/crash" ]; do sleep 0.05; done
      rm -f "#{dir}/crash"
      exit 3
    SH
    stub('worker', <<~SH)
      echo "start $$" >> "#{dir}/worker"
      # like Sidekiq, it takes its time to finish once told to stop
      trap 'echo "term $$" >> "#{dir}/worker"; echo 0 > "#{dir}/worker_exit.later"' TERM
      trap 'echo "tstp $$" >> "#{dir}/worker"' TSTP
      while [ ! -f "#{dir}/worker_exit" ]; do sleep 0.05; done
      exit "$(cat "#{dir}/worker_exit")"
    SH
    # what the store check reads: no older database, the schema there, and usable
    stub('psql', "echo 'f|t|t'\n")
  end

  # A failing example can leave the supervisor and its children running; they share one
  # process group, so a single kill ends them all.
  after do
    supervisors.select(&:alive?).each do |wait|
      Process.kill('KILL', -wait.pid)
    rescue Errno::ESRCH
      nil
    end
    FileUtils.remove_entry(dir)
  end

  def stub(name, body)
    path = File.join(bin_dir, name)
    File.write(path, "#!/bin/sh\n#{body}")
    FileUtils.chmod(0o755, path)
  end

  def start(extra = {})
    env = {
      'PATH' => "#{bin_dir}:#{ENV.fetch('PATH')}",
      'POSTGRES_HOST' => 'pg', 'POSTGRES_PORT' => nil, 'POSTGRES_USERNAME' => 'cw', 'POSTGRES_PASSWORD' => 'pw',
      'POSTGRES_DATABASE' => 'chatwoot_production', 'WAC_MEDIA_ROOT' => File.join(dir, 'media'),
      # nothing listens there: publishing the start status fails, and must not matter
      'REDIS_URL' => 'redis://127.0.0.1:1'
    }.merge(extra)
    stdin, out, wait = Open3.popen2e(env, 'ruby', script, 'worker', pgroup: true)
    stdin.close
    outputs << out
    supervisors << wait
    wait
  end

  def lines(name)
    path = File.join(dir, name)
    File.exist?(path) ? File.readlines(path, chomp: true) : []
  end

  def stop(wait)
    return unless wait&.alive?

    Process.kill('TERM', wait.pid)
    File.write(File.join(dir, 'worker_exit'), '0')
    Timeout.timeout(10) { wait.value }
  end

  def eventually(timeout = 10)
    Timeout.timeout(timeout) do
      sleep 0.05 until yield
    end
  end

  it 'starts the worker and the connector, and the connector gets the derived environment' do
    wait = start
    eventually { lines('worker').any? && lines('connector').any? }

    _, pid, engine, url, media_root, token = lines('connector').first.split
    expect(pid).to match(/\A\d+\z/)
    expect(engine).to eq('whatsmeow')
    expect(url).to eq('postgres://cw:pw@pg:5432/chatwoot_production?sslmode=prefer&search_path=whatsapp_connector')
    expect(media_root).to eq(File.join(dir, 'media'))
    expect(token).to match(/\A\h{64}\z/)
    expect(Dir.exist?(File.join(dir, 'media'))).to be(true)
  ensure
    stop(wait)
  end

  it 'forwards SIGTERM to both and exits with the worker status' do
    wait = start
    eventually { lines('worker').any? && lines('connector').any? }

    Process.kill('TERM', wait.pid)
    # the connector hears it while the worker is still draining: waiting for the worker
    # first would spend the container's stop grace period before the leases go back
    eventually { lines('connector').grep(/\Aterm /).size == 1 && lines('worker').grep(/\Aterm /).size == 1 }
    expect(wait).to be_alive

    File.rename(File.join(dir, 'worker_exit.later'), File.join(dir, 'worker_exit'))
    status = Timeout.timeout(10) { wait.value }

    expect(status.exitstatus).to eq(0)
  end

  it 'passes TSTP to the worker alone, so Sidekiq can be quieted without stopping anything' do
    wait = start
    eventually { lines('worker').any? && lines('connector').any? }

    Process.kill('TSTP', wait.pid)
    eventually { lines('worker').grep(/\Atstp /).size == 1 }

    expect(lines('connector').grep(/\Aterm /)).to be_empty
    expect(wait).to be_alive
  ensure
    stop(wait)
  end

  it 'keeps media in a directory of the container, not on a volume replicas share' do
    wait = start('WAC_MEDIA_ROOT' => nil)
    eventually { lines('connector').any? }

    expect(lines('connector').first.split[4]).to eq(File.join(Dir.tmpdir, 'whatsapp-connector'))
  ensure
    stop(wait)
  end

  it 'starts a crashed connector again with the same token, without touching the worker' do
    wait = start
    eventually { lines('connector').any? }
    worker_before = lines('worker')

    FileUtils.touch(File.join(dir, 'crash'))
    eventually { lines('connector').grep(/\Astart /).size == 2 }

    first, second = lines('connector').grep(/\Astart /).map(&:split)
    expect(second[1]).not_to eq(first[1])
    expect(second[5]).to eq(first[5])
    expect(lines('worker')).to eq(worker_before)
    expect(wait).to be_alive
  ensure
    stop(wait)
  end

  it 'stops the connector and exits with the status of a worker that died on its own' do
    wait = start
    eventually { lines('worker').any? && lines('connector').any? }

    File.write(File.join(dir, 'worker_exit'), '7')
    status = Timeout.timeout(10) { wait.value }

    expect(status.exitstatus).to eq(7)
    expect(lines('connector').grep(/\Aterm /).size).to eq(1)
  end

  it 'exits with the worker even while the database bootstrap hangs' do
    # a server that took the connection and stopped answering: psql waits for as long as it
    # is let, and only a signal ends it
    stub('psql', <<~SH)
      echo "start $$" >> "#{dir}/psql"
      trap 'echo "term $$" >> "#{dir}/psql"; exit 1' TERM
      while :; do sleep 0.05; done
    SH
    wait = start
    eventually { lines('worker').any? && lines('psql').any? }

    File.write(File.join(dir, 'worker_exit'), '7')
    status = Timeout.timeout(10) { wait.value }

    expect(status.exitstatus).to eq(7)
    expect(lines('psql').grep(/\Aterm /).size).to eq(1)
    expect(lines('connector')).to be_empty
  end

  it 'says once why the connector cannot start, keeps retrying, and leaves the worker alone' do
    stub('psql', <<~SH)
      echo "query" >> "#{dir}/psql"
      echo 'f|f|f'
    SH
    wait = start
    # three retries: the reason is the same each time
    eventually { lines('psql').size >= 3 }
    stop(wait)
    output = outputs.last.read

    expect(output.scan('schema whatsapp_connector does not exist').size).to eq(1)
    expect(output).to include('bundle exec rails db:migrate')
    expect(output.scan('could not publish the start status').size).to eq(1)
    expect(lines('connector')).to be_empty
    expect(lines('worker').grep(/\Astart /).size).to eq(1)
  end

  it 'refuses a WAC_DATABASE_URL database that does not exist, with the statement that creates it' do
    stub('psql', <<~SH)
      echo "query $*" >> "#{dir}/psql"
      echo 'psql: error: connection to server at "store" (10.0.0.9), port 5432 failed: FATAL:  database "wac_store" does not exist' >&2
      exit 2
    SH
    wait = start('WAC_DATABASE_URL' => 'postgres://wac:pw@store:5432/wac_store')
    eventually { lines('psql').size >= 2 }
    stop(wait)

    expect(lines('psql').first).to include('-h store', '-d wac_store')
    expect(outputs.last.read.scan('create it with CREATE DATABASE "wac_store"').size).to eq(1)
    expect(lines('connector')).to be_empty
  end

  describe WhatsappConnectorEmbedded do
    let(:base) { { 'POSTGRES_HOST' => 'pg', 'POSTGRES_USERNAME' => 'cw', 'POSTGRES_PASSWORD' => 'p@ss:w', 'POSTGRES_DATABASE' => 'cw_db' } }

    let(:ok) { instance_double(Process::Status, success?: true) }
    let(:failed) { instance_double(Process::Status, success?: false) }
    let(:calls) { [] }

    def answering(out, err = '', status = ok)
      lambda do |_env, sql, db: nil|
        calls << [sql, db]
        [out, err, status]
      end
    end

    def url_for(extra = {}, state = "f|t|t\n")
      described_class.store_url(base.merge(extra), runner: answering(state))
    end

    def env_for(extra = {})
      described_class.connector_env(base.merge(extra), media_token: 'tok', media_root: '/m', database_url: 'postgres://x')
    end

    it 'puts the store in the whatsapp_connector schema of the database Rails connects to' do
      url = url_for('DATABASE_URL' => 'postgres://u:secret@db.internal:6543/app?sslmode=require')

      expect(url).to eq('postgres://u:secret@db.internal:6543/app?sslmode=require&search_path=whatsapp_connector')
    end

    it 'keeps an installation that already has a database of the connector on it' do
      expect(url_for({}, "t|t|t\n")).to eq('postgres://cw:p%40ss%3Aw@pg:5432/cw_db_whatsapp_connector?sslmode=prefer')
      expect(url_for({}, "t|f|f\n")).to end_with('/cw_db_whatsapp_connector?sslmode=prefer')
    end

    it 'creates nothing, and says how to create the schema when it is missing' do
      expect { url_for({}, "f|f|f\n") }
        .to raise_error(WhatsappConnectorEmbedded::StartFailure) { |error|
          expect(error.message).to start_with('schema whatsapp_connector does not exist in database cw_db: ')
          expect(error.message).to include('bundle exec rails db:migrate', 'CREATE SCHEMA whatsapp_connector AUTHORIZATION "cw"')
        }
      expect(calls.size).to eq(1)
      expect(calls.first.first).to start_with('SELECT')
      expect(calls.first.first).not_to match(/CREATE (DATABASE|SCHEMA)/)
    end

    it 'says which grant is missing when the schema is there but not usable by this user' do
      expect { url_for({}, "f|t|f\n") }
        .to raise_error(WhatsappConnectorEmbedded::StartFailure,
                        /user cw lacks USAGE or CREATE on schema whatsapp_connector .*GRANT USAGE, CREATE ON SCHEMA whatsapp_connector TO "cw"/)
    end

    it 'tells a database that does not answer apart from a missing schema' do
      runner = answering('', "psql: error: connection to server at \"pg\", port 5432 failed: Connection refused\nmore\n", failed)

      expect { described_class.store_url(base, runner: runner) }
        .to raise_error(WhatsappConnectorEmbedded::StartFailure, /could not query database cw_db at pg:5432 as cw \(.*Connection refused\): check/)
    end

    describe '.check_explicit_store' do
      let(:explicit) { base.merge('WAC_DATABASE_URL' => 'postgres://wac:s%2Blt@store-db:6000/wac_store?sslmode=require') }

      it 'checks the database WAC_DATABASE_URL names, on its own server and with its own credentials' do
        described_class.check_explicit_store(explicit, runner: answering("1\n"))

        expect(calls).to eq([['SELECT 1', { host: 'store-db', port: '6000', user: 'wac', password: 's+lt',
                                            database: 'wac_store', options: { 'sslmode' => 'require' } }]])
      end

      it 'refuses a database that does not exist with the statement that creates it, and creates nothing' do
        runner = answering('', "psql: error: connection to server at \"store-db\" failed: FATAL:  database \"wac_store\" does not exist\n",
                           failed)

        expect { described_class.check_explicit_store(explicit, runner: runner) }
          .to raise_error(WhatsappConnectorEmbedded::StartFailure) { |error|
            expect(error.message).to start_with('database wac_store named by WAC_DATABASE_URL does not exist on store-db:6000: ')
            expect(error.message).to include('create it with CREATE DATABASE "wac_store"')
          }
        expect(calls.map(&:first)).to eq(['SELECT 1'])
      end

      it 'says the server does not answer when that is the failure' do
        runner = answering('', "psql: error: connection to server at \"store-db\", port 6000 failed: Connection refused\n", failed)

        expect { described_class.check_explicit_store(explicit, runner: runner) }
          .to raise_error(WhatsappConnectorEmbedded::StartFailure,
                          /could not query database wac_store at store-db:6000 .*WAC_DATABASE_URL is right/)
      end

      it 'reads credentials, host and port from the query, as lib/pq does' do
        env = base.merge('WAC_DATABASE_URL' => 'postgres://store-db/wac_store?user=wac&password=se%2Bcret&host=other-db&port=6001')
        described_class.check_explicit_store(env, runner: answering("1\n"))

        expect(calls.first.last).to include(host: 'other-db', port: '6001', user: 'wac', password: 'se+cret', database: 'wac_store')
      end

      it 'names the database libpq picked when the URL names none, from the server answer' do
        runner = answering('', "psql: error: connection to server at \"store-db\" failed: FATAL:  database \"wac_store\" does not exist\n", failed)

        expect { described_class.check_explicit_store(base.merge('WAC_DATABASE_URL' => 'postgres://wac@store-db'), runner: runner) }
          .to raise_error(WhatsappConnectorEmbedded::StartFailure) { |error|
            expect(error.message).to start_with('database wac_store named by WAC_DATABASE_URL does not exist on store-db: ')
          }
        expect(calls.first.last).not_to include(:database, :password, :port)
      end

      it 'dials localhost over TCP when no host is given anywhere, as the connector does' do
        described_class.check_explicit_store(base.merge('WAC_DATABASE_URL' => 'postgres:///wac_store?user=wac'), runner: answering("1\n"))
        described_class.check_explicit_store(base.merge('WAC_DATABASE_URL' => 'postgres:///wac_store?user=wac', 'PGHOST' => 'pg-env'),
                                             runner: answering("1\n"))

        expect(calls.map { |call| call.last[:host] }).to eq(['localhost', nil])
      end

      it 'decodes a plus in a query value as a space and reads lib/pq names, as the connector does' do
        db = described_class.explicit_database('postgres://wac:a+b@store-db/wac_store?password=with+space&dbname=other&database=ignored')

        expect(db).to include(password: 'with space', database: 'other')
        expect(described_class.explicit_database('postgres://wac:a+b@store-db/wac_store')[:password]).to eq('a+b')
      end

      it 'leaves PGPASSWORD to psql when the URL carries no password' do
        expect(described_class.psql_env(described_class.explicit_database('postgres://wac@store-db/wac_store'))).to eq({})
      end

      it 'leaves port, user and database to libpq when the URL names none of them' do
        stub('psql', %(echo "$@" > "#{dir}/psql_args"\necho 1\n))
        path = ENV.fetch('PATH')
        ENV['PATH'] = "#{bin_dir}:#{path}"

        described_class.check_explicit_store(base.merge('WAC_DATABASE_URL' => 'postgres://store-db'))

        args = File.read(File.join(dir, 'psql_args'))
        expect(args).to include('-h store-db -c SELECT 1')
        expect(args).not_to match(/ -[pUd] /)
      ensure
        ENV['PATH'] = path
      end

      it 'refuses a URL that does not parse without repeating it, since it carries the password' do
        env = base.merge('WAC_DATABASE_URL' => 'postgres://wac:my secret@store-db/wac_store')

        expect { described_class.check_explicit_store(env, runner: answering('')) }
          .to raise_error(WhatsappConnectorEmbedded::StartFailure) { |error| expect(error.message).not_to include('secret') }
        expect(calls).to be_empty
      end

      it 'leaves a store that is not Postgres to the connector' do
        described_class.check_explicit_store(base.merge('WAC_DATABASE_URL' => 'sqlite:///data/wac.db'), runner: answering(''))

        expect(calls).to be_empty
      end
    end

    it 'follows PGSSLMODE and escapes credentials when the URL names no sslmode' do
      expect(url_for('PGSSLMODE' => 'disable')).to eq('postgres://cw:p%40ss%3Aw@pg:5432/cw_db?sslmode=disable&search_path=whatsapp_connector')
    end

    it 'takes from POSTGRES_* what the URL leaves out, as Rails merges them' do
      expect(url_for('DATABASE_URL' => 'postgresql://u@db.internal/app'))
        .to eq('postgres://u:p%40ss%3Aw@db.internal:5432/app?sslmode=prefer&search_path=whatsapp_connector')
    end

    it 'reads connection fields from the query as Rails does, over the URL parts' do
      db = described_class.chatwoot_database(
        base.merge('DATABASE_URL' => 'postgres://cw@pg:5432/chatwoot?password=s%40cret&username=other&database=cw2')
      )

      expect(db.values_at(:user, :password, :database)).to eq(%w[other s@cret cw2])
    end

    it 'keeps the TLS options of the URL and drops the ones only Rails understands' do
      url = url_for('DATABASE_URL' => 'postgres://u:s@db/app?pool=5&sslmode=verify-full&sslrootcert=/ca.pem&checkout_timeout=5')

      expect(url).to eq('postgres://u:s@db:5432/app?sslmode=verify-full&sslrootcert=%2Fca.pem&search_path=whatsapp_connector')
    end

    it 'escapes a space as %20 and reads a plus in the URL as a plus' do
      expect(url_for('POSTGRES_PASSWORD' => 'with space')).to start_with('postgres://cw:with%20space@')
      expect(described_class.chatwoot_database('DATABASE_URL' => 'postgres://u:a+b@db/app')[:password]).to eq('a+b')
    end

    it 'refuses a DATABASE_URL that does not parse without repeating it' do
      expect { described_class.chatwoot_database('DATABASE_URL' => 'postgres://cw:se cret@db/app') }
        .to raise_error(WhatsappConnectorEmbedded::StartFailure) { |error| expect(error.message).not_to include('se cret') }
    end

    it 'reads a plus in a query value as a plus, as Rails does' do
      db = described_class.chatwoot_database('DATABASE_URL' => 'postgres://db/app?user=u%2Bv&password=a+b%20c')

      expect(db).to include(user: 'u+v', password: 'a+b c')
    end

    it 'brackets an IPv6 host once' do
      expect(url_for('DATABASE_URL' => 'postgres://u:s@[::1]:5432/app')).to start_with('postgres://u:s@[::1]:5432/')
      expect(described_class.chatwoot_database('DATABASE_URL' => 'postgres://u:s@[::1]:5432/app')[:host]).to eq('::1')
    end

    it 'hands the URL TLS options to psql through the variables libpq reads' do
      db = described_class.chatwoot_database('DATABASE_URL' => 'postgres://u:s@db/app?sslmode=verify-full&sslcert=/c&pool=5')

      expect(described_class.psql_env(db)).to eq('PGPASSWORD' => 's', 'PGSSLMODE' => 'verify-full', 'PGSSLCERT' => '/c')
    end

    it 'maps the Chatwoot names the connector knows by another name' do
      env = env_for('WHATSAPP_CONNECTOR_EVENT_SHARDS' => '8', 'WHATSAPP_CONNECTOR_REDIS_PREFIX' => 'x:')

      expect(env).to include('WAC_EVENT_SHARDS' => '8', 'WAC_REDIS_PREFIX' => 'x:', 'WAC_ENGINE' => 'whatsmeow',
                             'WAC_MEDIA_ROOT' => '/m', 'WAC_MEDIA_TOKEN' => 'tok', 'WAC_DATABASE_URL' => 'postgres://x')
    end

    it 'never overrides an explicit WAC_* value' do
      env = env_for('WAC_ENGINE' => 'fake', 'WAC_DATABASE_URL' => 'sqlite:x.db', 'WAC_EVENT_SHARDS' => '4',
                    'WHATSAPP_CONNECTOR_EVENT_SHARDS' => '8')

      expect(env.keys).not_to include('WAC_ENGINE', 'WAC_DATABASE_URL', 'WAC_EVENT_SHARDS')
    end

    # The Redis the suite runs against. CI sets no REDIS_URL, and the helper falls back to the same default.
    def redis_env
      { 'REDIS_URL' => ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
        'WHATSAPP_CONNECTOR_REDIS_PREFIX' => "spec#{SecureRandom.hex(4)}:", 'WAC_INSTANCE' => 'i1' }
    end

    it 'publishes the reason and its index entry on the Redis the connector registers in, and clears both', :redis_streams do
      env = redis_env
      key = described_class.failure_key(env)
      index = described_class.failure_index(env)
      redis = Redis.new(url: env['REDIS_URL'])
      report = described_class::FailureReport.new(env)
      allow(described_class).to receive(:log)

      report.failed('schema missing')
      expect(JSON.parse(redis.get(key))).to include('error' => 'schema missing')
      expect(redis.ttl(key)).to be_between(1, described_class::FAILURE_TTL)
      expect(redis.zscore(index, 'i1')).to be > Time.now.to_i
      expect(redis.ttl(index)).to be_between(1, described_class::FAILURE_TTL)

      report.recovered
      expect([redis.exists?(key), redis.zscore(index, 'i1')]).to eq([false, nil])
    ensure
      redis&.del(key, index)
    end

    it 'drops from the index the entries that expired', :redis_streams do
      env = redis_env
      index = described_class.failure_index(env)
      redis = Redis.new(url: env['REDIS_URL'])
      redis.zadd(index, Time.now.to_i - 1, 'gone-worker')
      allow(described_class).to receive(:log)

      described_class::FailureReport.new(env).failed('schema missing')

      expect(redis.zrange(index, 0, -1)).to eq(['i1'])
    ensure
      redis&.del(described_class.failure_key(env), index)
    end

    it 'reaches a Redis whose URL names an IPv6 address' do
      skip 'no IPv6 loopback here' unless Socket.ip_address_list.any?(&:ipv6_loopback?)

      server = TCPServer.new('::1', 0)
      received = Queue.new
      answering = Thread.new do
        client = server.accept
        received << client.readpartial(1024)
        client.write("+OK\r\n")
        client.close
      end

      reply = described_class.redis_command({ 'REDIS_URL' => "redis://[::1]:#{server.addr[1]}" }, 'DEL', 'k')

      expect(reply).to eq("+OK\r\n")
      expect(received.pop).to eq("*2\r\n$3\r\nDEL\r\n$1\r\nk\r\n")
    ensure
      answering&.join(1)
      server&.close
    end

    it 'gives up on a Redis that took the connection and stopped answering' do
      server = TCPServer.new('127.0.0.1', 0)
      silent = Thread.new { server.accept }
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      expect { described_class.redis_command({ 'REDIS_URL' => "redis://127.0.0.1:#{server.addr[1]}" }, 'DEL', 'k') }
        .to raise_error(Timeout::Error)
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < WhatsappConnectorEmbedded::REDIS_TIMEOUT + 1
    ensure
      silent&.kill
      server&.close
    end

    describe WhatsappConnectorEmbedded::Supervisor do
      let(:supervisor) { described_class.new(['true'], env: {}, binary: 'connector') }
      let(:failures) { supervisor.instance_variable_get(:@failures) }
      let(:clock) { [0.0] }
      let(:status) { instance_double(Process::Status, exitstatus: 1) }

      before do
        allow(failures).to receive(:recovered)
        allow(failures).to receive(:failed)
        allow(supervisor).to receive(:kill)
        allow(supervisor).to receive(:monotonic) { clock.first }
        allow(supervisor).to receive(:pause)
      end

      # Two rounds of 120 s each, the second one stopping the loop. A spawned round spends
      # its time in the connector, the other one in a store check that ends up failing.
      def supervise(spawned:)
        rounds = 0
        allow(supervisor).to receive(:locate_store) do
          rounds += 1
          supervisor.instance_variable_set(:@stopping, true) if rounds == 2
          next 'postgres://store-db/chatwoot' if spawned

          clock[0] += 120
          raise WhatsappConnectorEmbedded::StartFailure, 'store unreachable'
        end
        stub_connector_run
        supervisor.send(:keep_connector_running)
      end

      def stub_connector_run
        allow(FileUtils).to receive(:mkdir_p)
        allow(WhatsappConnectorEmbedded).to receive(:connector_env).and_return({})
        allow(Process).to receive(:spawn).and_return(4242)
        allow(Process).to receive(:wait2) do
          clock[0] += 120
          [4242, status]
        end
      end

      it 'keeps the reason of a store check that took long and failed: nothing ran' do
        supervise(spawned: false)

        expect(failures).not_to have_received(:recovered)
      end

      it 'clears the reason once a connector it spawned ran long enough' do
        supervise(spawned: true)

        expect(failures).to have_received(:recovered).once
      end
    end

    describe WhatsappConnectorEmbedded::FailureReport do
      let(:now) { [1000.0] }
      let(:published) { [] }
      let(:report) { described_class.new({ 'WAC_INSTANCE' => 'i1' }, clock: -> { now.first }) }

      before do
        allow(WhatsappConnectorEmbedded).to receive(:redis_commands) do |_env, *commands|
          published.concat(commands.filter_map { |name, key| [name, key] if %w[SET DEL].include?(name) })
        end
        allow(WhatsappConnectorEmbedded).to receive(:log)
      end

      it 'logs a reason once while it repeats, and again when it changes or after a while' do
        3.times { report.failed('schema missing') }
        now[0] += WhatsappConnectorEmbedded::REPEAT_FAILURE_AFTER - 1
        report.failed('schema missing')
        report.failed('no grant')
        now[0] += WhatsappConnectorEmbedded::REPEAT_FAILURE_AFTER
        report.failed('no grant')

        expect(WhatsappConnectorEmbedded).to have_received(:log).with(/\Aschema missing\. Retrying/).once
        expect(WhatsappConnectorEmbedded).to have_received(:log).with(/\Ano grant\. Retrying/).twice
        expect(published).to all(eq(['SET', 'wa:embedded:i1']))
        expect(published.size).to eq(6)
      end

      it 'never logs or publishes a password that a reason carries' do
        report.failed('bad URI (is not URI?): "postgres://wac:my secret@store-db/wac_store"')

        expect(WhatsappConnectorEmbedded).to have_received(:log).with(including('postgres://wac:***@store-db/wac_store'))
        expect(WhatsappConnectorEmbedded).not_to have_received(:log).with(including('secret'))
        expect(WhatsappConnectorEmbedded).to have_received(:redis_commands) do |_env, *commands|
          expect(commands.first[2]).to include('postgres://wac:***@store-db/wac_store')
          expect(commands.flatten.join).not_to include('secret')
        end
      end

      it 'redacts a password given as a query parameter too' do
        report.failed('bad URI (is not URI?): "postgres://bad host/app?user=cw&password=secret&sslmode=disable"')

        expect(WhatsappConnectorEmbedded).to have_received(:log).with(including('?user=cw&password=***&sslmode=disable'))
      end

      it 'redacts all of a query password, spaces and quotes included' do
        report.failed(%(bad URI (is not URI?): "postgres://cw@bad host/app?password= top "secret" here"))

        expect(WhatsappConnectorEmbedded).to have_received(:log).with(satisfy { |line| line.scan('secret').empty? })
      end

      it 'does not repeat a Redis password from a URL that would not parse' do
        allow(WhatsappConnectorEmbedded).to receive(:redis_commands).and_call_original
        allow(WhatsappConnectorEmbedded).to receive(:log).and_call_original
        report = described_class.new({ 'REDIS_URL' => 'redis://:super secret@redis' })

        expect { report.failed('schema missing') }
          .to output(a_string_including('could not publish').and(satisfy { |text| text.scan('super secret').empty? })).to_stderr
      end

      it 'forgets the reason once the connector ran, so the same failure is news again' do
        report.failed('connector exited (status 1)')
        report.recovered
        report.failed('connector exited (status 1)')

        expect(WhatsappConnectorEmbedded).to have_received(:log).twice
        expect(published).to eq([%w[SET wa:embedded:i1], %w[DEL wa:embedded:i1], %w[SET wa:embedded:i1]])
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
