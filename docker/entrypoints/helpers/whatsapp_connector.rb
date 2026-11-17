#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs fazer-ai/whatsapp-connector next to Sidekiq, in the same container.
#
# The image carries the connector's binary (docker/Dockerfile copies it from the published
# image at a pinned version), and sidekiq.sh hands the worker's command to this file instead
# of exec'ing it unless WHATSAPP_CONNECTOR_ENABLED or WHATSAPP_CONNECTOR_EMBEDDED is false. From here on this process is PID 1 and the parent of both:
#
# - Sidekiq is the container. When it exits, for whatever reason, the connector is stopped
#   and this process exits with Sidekiq's status, so the restart policy and the healthcheck
#   see exactly what they saw before the connector was here.
# - The connector is not. When it exits it is started again, with a backoff, and Sidekiq is
#   never touched: a WhatsApp outage must not take the worker down with it.
# - SIGTERM and SIGINT go to both. The connector answers by handing its session leases back
#   to Redis, which is what lets another instance (or this one, restarted) pick the sessions
#   up at once instead of waiting for the leases to run out.
#
# Everything the connector needs is derived from what Chatwoot already has: the same Redis
# (it reads REDIS_URL and REDIS_PASSWORD itself), its store in the `whatsapp_connector`
# schema of Chatwoot's own database (created by a Chatwoot migration, never from here), a
# media directory local to the container
# (a cache, and one a second replica must not share: each connector sweeps the temporary
# files it does not know of), and a media token generated per container start, which Chatwoot reads from the connector's
# registry entry in Redis. Any WAC_* variable set explicitly wins over the derived value.
#
# Plain Ruby and the standard library only: this runs before, and outside of, bundler.

require 'fileutils'
require 'json'
require 'open3'
require 'openssl'
require 'securerandom'
require 'socket'
require 'time'
require 'timeout'
require 'tmpdir'
require 'uri'

# rubocop:disable Style/OneClassPerFile -- one self-contained file run before bundler, so nothing to require the classes from
module WhatsappConnectorEmbedded # rubocop:disable Metrics/ModuleLength -- one self-contained file run before bundler; the length is the Rails-compatible URL handling
  # Where the store lives: this schema of Chatwoot's database, which
  # db/migrate/20261117164815_create_whatsapp_connector_schema.rb creates.
  SCHEMA = 'whatsapp_connector'
  # The database of its own an installation got before the schema, created on the first
  # start by earlier versions of this file. One that has it keeps it: its pairings are there.
  LEGACY_DATABASE_SUFFIX = '_whatsapp_connector'
  MAX_BACKOFF = 30
  # A start that keeps failing for the same reason is logged once, and again only this
  # often, instead of on every retry.
  REPEAT_FAILURE_AFTER = 600
  # How long the reason a start failed stays readable in Redis (the super admin health page
  # shows it). Every retry, at most MAX_BACKOFF apart, writes it again.
  FAILURE_TTL = 120
  # The most a publish of that reason may take, connect and TLS included: it runs in the
  # supervising thread, and a Redis that took the connection and stopped answering must not
  # stop the retries or hold a shutdown.
  REDIS_TIMEOUT = 3
  # A connector that stayed up this long is treated as healthy, and its next crash starts
  # the backoff over instead of continuing it.
  HEALTHY_AFTER = 60

  # The defaults config/database.yml falls back to, per environment, so that the connector's
  # database sits next to the one Rails actually connects to.
  DATABASE_DEFAULTS = {
    'production' => { 'database' => 'chatwoot_production', 'username' => 'chatwoot_prod', 'password' => 'chatwoot_prod' },
    'test' => { 'database' => 'chatwoot_test', 'username' => 'postgres', 'password' => '' },
    'development' => { 'database' => 'chatwoot_dev', 'username' => 'postgres', 'password' => '' }
  }.freeze

  module_function

  def log(message)
    warn "[whatsapp-connector] #{message}"
  end

  # The connection options that mean the same to libpq (Rails, psql) and to lib/pq (the
  # connector), each with the variable psql reads it from. Anything else a DATABASE_URL may
  # carry is Rails' own (pool, checkout_timeout, ...), and lib/pq would send it to the server
  # as a startup parameter, which the server refuses.
  CONNECTION_OPTIONS = {
    'sslmode' => 'PGSSLMODE',
    'sslcert' => 'PGSSLCERT',
    'sslkey' => 'PGSSLKEY',
    'sslrootcert' => 'PGSSLROOTCERT',
    'connect_timeout' => 'PGCONNECT_TIMEOUT'
  }.freeze

  # Chatwoot's own connection, as Rails resolves it: what DATABASE_URL says, over the
  # POSTGRES_* parameters, over database.yml's defaults. Rails merges the URL into the
  # config field by field, so a URL without a password still takes POSTGRES_PASSWORD.
  def chatwoot_database(env)
    defaults = DATABASE_DEFAULTS.fetch(env.fetch('RAILS_ENV', 'production'), DATABASE_DEFAULTS['production'])
    config = {
      host: present(env['POSTGRES_HOST']) || 'localhost',
      port: present(env['POSTGRES_PORT']) || '5432',
      user: env.fetch('POSTGRES_USERNAME', defaults['username']),
      password: env.fetch('POSTGRES_PASSWORD', defaults['password']),
      database: env.fetch('POSTGRES_DATABASE', defaults['database']),
      options: {}
    }
    url = env['DATABASE_URL'].to_s
    url.empty? ? config : config.merge(database_from_url(url))
  rescue URI::Error, ArgumentError
    # Raised with the URL in its message, password included, and this text is published.
    raise StartFailure, 'DATABASE_URL is not a valid URL (a password with reserved characters has to be percent-encoded)'
  end

  # Only the fields the URL actually carries, so the rest fall through to the defaults. A
  # field may also come as a query parameter, which wins over the URL's own parts, as it
  # does in Rails' resolver (under Rails' name or libpq's).
  def database_from_url(url)
    uri = URI(url)
    query = query_params(uri.query.to_s)
    url_fields(uri).merge(query_fields(query)).merge(options: query.slice(*CONNECTION_OPTIONS.keys))
  end

  # Percent-decoded and nothing more, as Rails' resolver reads it: a form decoder would turn
  # a literal plus into a space, and a password with one would connect Rails and not this.
  def query_params(query)
    query.split('&').to_h { |pair| pair.split('=', 2) }.transform_values { |value| URI::RFC2396_PARSER.unescape(value.to_s) }
  end

  def url_fields(uri)
    path = uri.path.to_s.delete_prefix('/')
    {
      host: present(uri.hostname),
      port: uri.port&.to_s,
      user: uri.user && URI.decode_uri_component(uri.user),
      password: uri.password && URI.decode_uri_component(uri.password),
      database: path.empty? ? nil : URI.decode_uri_component(path)
    }.compact
  end

  def query_fields(query)
    {
      host: present(query['host']),
      port: present(query['port']),
      user: query['username'] || query['user'],
      password: query['password'],
      database: present(query['database']) || present(query['dbname'])
    }.compact
  end

  # Why the connector cannot start, in words an operator can act on. Raised before the
  # connector is spawned, so the reason is ours and not a stack of the connector's own.
  class StartFailure < StandardError; end

  def legacy_database_name(env)
    "#{chatwoot_database(env)[:database]}#{LEGACY_DATABASE_SUFFIX}"
  end

  # lib/pq, the connector's driver, defaults to sslmode=require where libpq (what Rails
  # uses) defaults to prefer. Left unset, a server without TLS that Chatwoot reaches fine
  # would refuse the connector, so the URL says prefer unless the operator said otherwise.
  #
  # lib/pq sends any other query parameter as a run-time parameter, which is how
  # `search_path` reaches the server. The connector refuses a path that leaves its tables
  # out or puts another schema in front of them, so it names the store's schema alone.
  def connector_database_url(env, database:, search_path: nil)
    db = chatwoot_database(env)
    options = { 'sslmode' => present(env['PGSSLMODE']) || 'prefer' }.merge(db[:options])
    options['search_path'] = search_path if search_path

    userinfo = [db[:user], db[:password]].compact.map { |part| URI.encode_uri_component(part) }.join(':')
    host = db[:host].include?(':') ? "[#{db[:host]}]" : db[:host]
    "postgres://#{userinfo}#{'@' unless userinfo.empty?}#{host}:#{db[:port]}/" \
      "#{URI.encode_uri_component(database)}?#{URI.encode_www_form(options)}"
  end

  # The URL of the connector's store, after making sure it can be used. Nothing is created
  # here: the schema comes from Chatwoot's migrations, and a role without the privilege to
  # create it is told what to run instead of being retried forever.
  def store_url(env, runner: method(:psql))
    legacy, schema, privileged = store_state(env, runner)
    db = chatwoot_database(env)
    return connector_database_url(env, database: legacy_database_name(env)) if legacy
    return connector_database_url(env, database: db[:database], search_path: SCHEMA) if schema && privileged

    raise StartFailure, missing_privilege(db) if schema

    raise StartFailure, "schema #{SCHEMA} does not exist in database #{db[:database]}: run Chatwoot's migrations " \
                        "(bundle exec rails db:migrate), or create it with CREATE SCHEMA #{SCHEMA} AUTHORIZATION " \
                        "#{quote_ident(db[:user].to_s)}, or point WAC_DATABASE_URL at a database of the connector's own"
  end

  def missing_privilege(db)
    "user #{db[:user]} lacks USAGE or CREATE on schema #{SCHEMA} in database #{db[:database]}: run " \
      "GRANT USAGE, CREATE ON SCHEMA #{SCHEMA} TO #{quote_ident(db[:user].to_s)} as its owner, " \
      "or point WAC_DATABASE_URL at a database of the connector's own"
  end

  # One round trip: whether the database of an older installation is there, whether the
  # schema is, and whether this role may use it and create its tables in it.
  def store_state(env, runner)
    schema = "to_regnamespace(#{quote_literal(SCHEMA)})"
    out, err, status = runner.call(env, <<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs -- no ActiveSupport here, and psql takes the newlines
      SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = #{quote_literal(legacy_database_name(env))}),
      #{schema} IS NOT NULL,
      COALESCE(has_schema_privilege(#{schema}, 'USAGE') AND has_schema_privilege(#{schema}, 'CREATE'), false)
    SQL
    raise StartFailure, unreachable(env, err) unless status.success?

    out.strip.split('|').map { |value| value == 't' }
  end

  # A WAC_DATABASE_URL is taken as given, and never created: a misspelled name, or a
  # database that was not restored, would start the connector on an empty store and drop
  # every pairing with no error at all. So a Postgres one is checked to exist, and one that
  # does not is refused with the statement that creates it.
  def check_explicit_store(env, runner: method(:psql))
    url = env['WAC_DATABASE_URL']
    scheme = url[/\A[a-z][a-z0-9+.-]*(?=:)/i].to_s.downcase
    return unless %w[postgres postgresql].include?(scheme)

    db = explicit_database(url)
    # The one default lib/pq does not share with libpq: with no host anywhere it dials TCP on
    # localhost, where psql would try a Unix socket the connector never uses.
    db[:host] ||= 'localhost' unless present(env['PGHOST'])
    _out, err, status = runner.call(env, 'SELECT 1', db: db)
    return if status.success?

    # The name comes from the server's answer: with the URL silent on it, libpq picked it
    # (PGDATABASE, or the user's name), and that is the one the connector would open too.
    missing = err[/database "(.+?)" does not exist/, 1]
    raise StartFailure, unreachable(env, err, db: db, source: 'WAC_DATABASE_URL') unless missing

    raise StartFailure, "database #{missing} named by WAC_DATABASE_URL does not exist#{location(db)}: " \
                        "create it with CREATE DATABASE #{quote_ident(missing)} (it is never created automatically, " \
                        'so a mistyped name cannot start the connector on an empty store), or fix WAC_DATABASE_URL'
  end

  def location(db, preposition = 'on')
    place = [db[:host], db[:port]].compact.join(':')
    place.empty? ? '' : " #{preposition} #{place}"
  end

  # Read the way the connector reads it, which is lib/pq's way and not Rails': its parameter
  # names (user, password, host, port, dbname), query values form-decoded (a plus is a
  # space), and query parameters over the URL's own parts. Only what the URL says: whatever it
  # leaves out is libpq's to fill from the PG* variables and its defaults, as lib/pq does. A URL
  # that does not parse is refused without repeating it, since it carries the password.
  def explicit_database(url)
    uri = URI(url)
    query = URI.decode_www_form(uri.query.to_s).to_h
    from_query = { host: present(query['host']), port: present(query['port']), user: query['user'],
                   password: query['password'], database: present(query['dbname']) }
    explicit_url_parts(uri).merge(from_query.compact).merge(options: query.slice(*CONNECTION_OPTIONS.keys))
  rescue URI::Error, ArgumentError
    raise StartFailure, 'WAC_DATABASE_URL is not a valid URL (a password with reserved characters has to be percent-encoded)'
  end

  # The URL's own parts, percent-decoded only: a plus there is a plus.
  def explicit_url_parts(uri)
    decode = ->(part) { part && URI.decode_uri_component(part) }
    { host: present(uri.hostname), port: uri.port&.to_s, user: decode.call(uri.user), password: decode.call(uri.password),
      database: present(decode.call(uri.path.to_s.delete_prefix('/'))) }.compact
  end

  def unreachable(env, err, db: chatwoot_database(env), source: nil)
    settings = source || 'POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USERNAME and POSTGRES_PASSWORD (or DATABASE_URL)'
    "could not query database #{db[:database]}#{location(db, 'at')} as #{db[:user]} (#{err.strip.lines.first&.strip}): " \
      "check that PostgreSQL is up and that #{settings} #{source ? 'is' : 'are'} right"
  end

  # `on_spawn` gets psql's pid, so whoever runs it can end it: psql has no timeout of its own,
  # and a server that stopped answering would otherwise hold it, and its caller, forever.
  #
  # Whatever the configuration leaves out is left to libpq's own defaults.
  def psql(env, sql, db: chatwoot_database(env), on_spawn: nil)
    named = { '-h' => db[:host], '-p' => db[:port], '-U' => db[:user], '-d' => db[:database] }
            .select { |_, value| present(value) }.flatten
    Open3.popen3(psql_env(db), 'psql', '-X', '-q', '-t', '-A', '-v', 'ON_ERROR_STOP=1', *named, '-c', sql) do |stdin, out, err, wait|
      stdin.close
      on_spawn&.call(wait.pid)
      error = Thread.new { err.read }
      [out.read, error.value, wait.value]
    end
  end

  # The URL's connection options reach psql the way libpq reads them from the environment;
  # the ones set as PG* variables on the container are inherited as they are.
  # A password the configuration does not give leaves PGPASSWORD (or ~/.pgpass) as it was.
  def psql_env(db)
    base = db[:password].nil? ? {} : { 'PGPASSWORD' => db[:password] }
    db.fetch(:options, {}).each_with_object(base) do |(option, value), pg_env|
      pg_env[CONNECTION_OPTIONS.fetch(option)] = value
    end
  end

  def quote_ident(name)
    %("#{name.gsub('"', '""')}")
  end

  def quote_literal(value)
    "'#{value.gsub("'", "''")}'"
  end

  # The connector's environment: Chatwoot's, plus what the connector calls by another name
  # or cannot derive on its own. An explicit WAC_* value is never overwritten.
  def connector_env(env, media_token:, media_root:, database_url: nil)
    derived = {
      'WAC_ENGINE' => 'whatsmeow',
      'WAC_MEDIA_ROOT' => media_root,
      'WAC_MEDIA_TOKEN' => media_token
    }
    derived['WAC_EVENT_SHARDS'] = env['WHATSAPP_CONNECTOR_EVENT_SHARDS'] if present(env['WHATSAPP_CONNECTOR_EVENT_SHARDS'])
    derived['WAC_REDIS_PREFIX'] = env['WHATSAPP_CONNECTOR_REDIS_PREFIX'] if present(env['WHATSAPP_CONNECTOR_REDIS_PREFIX'])
    derived['WAC_DATABASE_URL'] = database_url if database_url

    derived.reject { |key, _| present(env[key]) }
  end

  def present(value)
    value unless value.nil? || value.empty? # rubocop:disable Rails/Blank -- runs before bundler, without ActiveSupport
  end

  # A password inside any URL in the text, replaced: in the userinfo, and as a query
  # parameter, the two places a connection URL carries one.
  def redact(text)
    text.gsub(%r{([a-z][a-z0-9+.-]*://[^\s/@:]*:)[^@\n]*?@}i, '\\1***@')
        .gsub(/([?&;]password=)[^&\n]*/i, '\\1***')
  end

  # The key the reason for a failed start is published under, next to the connector's own
  # registry entry and under the same instance id, so the health page can show it for the
  # instance that never registered.
  def failure_key(env)
    "#{failure_index(env)}:#{failure_instance(env)}"
  end

  # The instances that published a reason, scored by when it expires, so a reader lists them
  # without scanning the whole Redis database for their keys.
  def failure_index(env)
    "#{present(env['WHATSAPP_CONNECTOR_REDIS_PREFIX']) || 'wa:'}embedded"
  end

  def failure_instance(env)
    present(env['WAC_INSTANCE']) || Socket.gethostname
  end

  # One Redis command over a plain socket, for the one thing this file writes there. The
  # redis gem is behind bundler, and this runs outside it. It reads the same two variables
  # the connector reads (REDIS_URL and REDIS_PASSWORD), so it reaches the Redis the connector
  # registers in, and the health page reads both from the same place.
  def redis_command(env, *command)
    redis_commands(env, command)
  end

  # Several commands over one connection, in order. The reply is the last one's. Only the
  # first line of each reply is read, so these are commands that answer in one line (SET,
  # DEL, ZADD and the like), never one that returns a value.
  def redis_commands(env, *commands)
    url = redis_url(env)
    Timeout.timeout(REDIS_TIMEOUT) do
      socket = redis_socket(env, url)
      redis_auth(env, url, socket)
      database = url.path.to_s.delete_prefix('/')
      redis_call(socket, 'SELECT', database) unless database.empty?
      commands.map { |command| redis_call(socket, *command) }.last
    ensure
      socket&.close
    end
  end

  def redis_url(env)
    URI(present(env['REDIS_URL']) || 'redis://127.0.0.1:6379')
  rescue URI::Error
    raise 'REDIS_URL is not a valid URL'
  end

  def redis_auth(env, url, socket)
    password = present(env['REDIS_PASSWORD']) || (url.password && URI.decode_uri_component(url.password))
    return unless password

    user = present(url.user) && URI.decode_uri_component(url.user)
    redis_call(socket, 'AUTH', *[user, password].compact)
  end

  def redis_socket(env, url)
    # hostname, not host: an IPv6 address comes without the brackets the URL needs.
    tcp = Socket.tcp(url.hostname, url.port || 6379, connect_timeout: REDIS_TIMEOUT)
    return tcp unless url.scheme == 'rediss'

    # set_params brings the system trust store and hostname verification along; without it
    # VERIFY_PEER rejects every certificate.
    context = OpenSSL::SSL::SSLContext.new
    context.set_params(verify_mode: env['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER)
    OpenSSL::SSL::SSLSocket.new(tcp, context).tap do |tls|
      tls.hostname = url.hostname
      tls.sync_close = true
      tls.connect
    end
  end

  def redis_call(socket, *command)
    socket.write("*#{command.size}\r\n#{command.map { |part| "$#{part.to_s.bytesize}\r\n#{part}\r\n" }.join}")
    reply = socket.gets("\r\n").to_s
    raise "Redis answered #{reply.strip.inspect} to #{command.first}" unless reply.start_with?('+', ':', '$')

    reply
  end

  # What a start that failed looked like, kept so it is said once rather than every retry,
  # and published so the super admin health page can say it too. A connector that ran long
  # enough to be called healthy clears it: the next failure is news again.
  class FailureReport
    def initialize(env, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @env = env
      @clock = clock
      @last = nil
      @logged_at = nil
      @publish_failed = false
    end

    # Credentials never leave this process: the reason goes to the log, to the health page
    # and to every account administrator who opens the inbox picker.
    def failed(reason)
      reason = WhatsappConnectorEmbedded.redact(reason)
      if reason != @last || @clock.call - @logged_at >= REPEAT_FAILURE_AFTER
        WhatsappConnectorEmbedded.log "#{reason}. Retrying in the background; this is logged again when the reason changes."
        @last = reason
        @logged_at = @clock.call
      end
      expires_at = Time.now.to_i + FAILURE_TTL
      publish(['SET', key, JSON.generate(error: reason, at: Time.now.utc.iso8601), 'EX', FAILURE_TTL],
              ['ZADD', index, expires_at, instance],
              ['ZREMRANGEBYSCORE', index, '-inf', "(#{Time.now.to_i}"],
              ['EXPIRE', index, FAILURE_TTL])
    end

    def recovered
      return if @last.nil?

      @last = nil
      publish(['DEL', key], ['ZREM', index, instance])
    end

    private

    # Losing the health page's copy must never stop the connector from being retried. A
    # Redis that refuses it is said once, since the connector would fail on it too.
    def publish(*commands)
      WhatsappConnectorEmbedded.redis_commands(@env, *commands)
      @publish_failed = false
    rescue StandardError => e
      WhatsappConnectorEmbedded.log "could not publish the start status to Redis: #{e.message}" unless @publish_failed
      @publish_failed = true
    end

    def key = WhatsappConnectorEmbedded.failure_key(@env)
    def index = WhatsappConnectorEmbedded.failure_index(@env)
    def instance = WhatsappConnectorEmbedded.failure_instance(@env)
  end

  class Supervisor
    def initialize(command, env: ENV.to_h, binary: ENV.fetch('WHATSAPP_CONNECTOR_BIN', 'whatsapp-connector'),
                   media_root: File.join(Dir.tmpdir, 'whatsapp-connector'))
      @command = command
      @env = env
      @binary = binary
      @media_root = present_or(env['WAC_MEDIA_ROOT'], media_root)
      # One token per container start rather than per connector start: a connector that
      # restarts keeps answering the token Chatwoot already read.
      @media_token = present_or(env['WAC_MEDIA_TOKEN'], SecureRandom.hex(32))
      @stopping = false
      @connector_pid = nil
      @bootstrap_pid = nil
      @wake_r, @wake_w = IO.pipe
      @failures = FailureReport.new(env)
    end

    def run
      trap_signals
      @sidekiq_pid = Process.spawn(*@command)
      connector = Thread.new { keep_connector_running }

      _, status = Process.wait2(@sidekiq_pid)
      log "worker exited (#{describe(status)}), stopping the connector" unless @stopping
      stop_connector
      connector.join
      exit_code(status)
    end

    private

    def trap_signals
      %w[TERM INT].each do |signal|
        Signal.trap(signal) do
          @stopping = true
          kill(signal, @sidekiq_pid)
          kill(signal, @connector_pid)
          kill(signal, @bootstrap_pid)
          wake
        end
      end
      # Sidekiq's own operational signals (TSTP quiets it, TTIN dumps its threads) reach this
      # process now, since it is PID 1. They are the worker's alone.
      %w[TSTP TTIN].each do |signal|
        Signal.trap(signal) { kill(signal, @sidekiq_pid) }
      end
    end

    def stop_connector
      @stopping = true
      kill('TERM', @connector_pid)
      kill('TERM', @bootstrap_pid)
      wake
    end

    def keep_connector_running
      backoff = 1
      until @stopping
        @spawned_at = nil
        status = run_connector_once
        break if @stopping

        # Healthy is a connector that ran that long, counted from its spawn: time spent
        # checking the store, however slow, is not a run.
        if @spawned_at && monotonic - @spawned_at >= HEALTHY_AFTER
          backoff = 1
          @failures.recovered
        end
        @failures.failed("connector exited (#{describe(status)})") if status
        pause(backoff)
        backoff = [backoff * 2, MAX_BACKOFF].min
      end
    end

    # The connector's status, or nil when it was not started: the reason is reported here,
    # where it is known, and the loop above only waits.
    def run_connector_once
      database_url = locate_store
      FileUtils.mkdir_p(@media_root)
      env = WhatsappConnectorEmbedded.connector_env(@env, media_token: @media_token, media_root: @media_root,
                                                          database_url: database_url)
      @connector_pid = Process.spawn(env, @binary, 'serve')
      @spawned_at = monotonic
      # a signal that landed between the spawn and the assignment above found no pid to forward to
      kill('TERM', @connector_pid) if @stopping
      _, status = Process.wait2(@connector_pid)
      @connector_pid = nil
      status
    rescue StandardError => e
      @failures.failed("connector did not start: #{e.message}") unless @stopping
      nil
    end

    # The derived URL, or nil when WAC_DATABASE_URL names the store (checked, never created).
    def locate_store
      if WhatsappConnectorEmbedded.present(@env['WAC_DATABASE_URL'])
        WhatsappConnectorEmbedded.check_explicit_store(@env, runner: method(:bootstrap_psql))
        return
      end

      WhatsappConnectorEmbedded.store_url(@env, runner: method(:bootstrap_psql))
    end

    # Tracked like the connector, so a worker that exits while the database is not answering
    # still takes the container down instead of waiting on psql.
    def bootstrap_psql(env, sql, db: WhatsappConnectorEmbedded.chatwoot_database(env))
      WhatsappConnectorEmbedded.psql(env, sql, db: db, on_spawn: lambda { |pid|
        @bootstrap_pid = pid
        # a stop that landed before the pid was known found nothing to signal
        kill('TERM', pid) if @stopping
      })
    ensure
      @bootstrap_pid = nil
    end

    def pause(seconds)
      @wake_r.wait_readable(seconds)
    end

    def wake
      @wake_w.write_nonblock('.')
    rescue IO::WaitWritable
      nil
    end

    def kill(signal, pid)
      Process.kill(signal, pid) if pid
    rescue Errno::ESRCH
      nil
    end

    def exit_code(status)
      status.exitstatus || (128 + status.termsig)
    end

    def describe(status)
      status.exitstatus ? "status #{status.exitstatus}" : "signal #{status.termsig}"
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def present_or(value, fallback)
      WhatsappConnectorEmbedded.present(value) || fallback
    end

    def log(message)
      WhatsappConnectorEmbedded.log(message)
    end
  end
end

# rubocop:enable Style/OneClassPerFile

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    WhatsappConnectorEmbedded.log 'no worker command given'
    exit 1
  end
  exit WhatsappConnectorEmbedded::Supervisor.new(ARGV).run
end
