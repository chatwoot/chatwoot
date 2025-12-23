require 'rubygems'
require 'minitest/autorun'
require 'net/http/persistent'
require 'stringio'

HAVE_OPENSSL = defined?(OpenSSL::SSL)

module Net::HTTP::Persistent::TestConnect
  def self.included mod
    mod.send :alias_method, :orig_connect, :connect

    def mod.use_connect which
      self.send :remove_method, :connect
      self.send :alias_method, :connect, which
    end
  end

  def host_down_connect
    raise Errno::EHOSTDOWN
  end

  def test_connect
    unless use_ssl? then
      io = Object.new
      def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end

      @socket = Net::BufferedIO.new io

      return
    end

    io = open '/dev/null'
    def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end

    @ssl_context ||= OpenSSL::SSL::SSLContext.new

    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER unless
      @ssl_context.verify_mode

    s = OpenSSL::SSL::SSLSocket.new io, @ssl_context

    @socket = Net::BufferedIO.new s
  end

  def refused_connect
    raise Errno::ECONNREFUSED
  end
end

class Net::HTTP
  include Net::HTTP::Persistent::TestConnect
end

class TestNetHttpPersistent < Minitest::Test

  def setup
    @http = Net::HTTP::Persistent.new

    @uri    = URI 'http://example.com/path'
    @uri_v6 = URI 'http://[2001:db8::1]/path'

    ENV.delete 'http_proxy'
    ENV.delete 'HTTP_PROXY'
    ENV.delete 'http_proxy_user'
    ENV.delete 'HTTP_PROXY_USER'
    ENV.delete 'http_proxy_pass'
    ENV.delete 'HTTP_PROXY_PASS'
    ENV.delete 'no_proxy'
    ENV.delete 'NO_PROXY'

    Net::HTTP.use_connect :test_connect
  end

  def teardown
    Net::HTTP.use_connect :orig_connect
  end

  class BasicConnection
    attr_accessor :started, :finished, :address, :port, :use_ssl,
                  :read_timeout, :open_timeout, :keep_alive_timeout
    attr_accessor :ciphers, :ssl_timeout, :ssl_version, :min_version,
                  :max_version, :verify_depth, :verify_mode, :cert_store,
                  :ca_file, :ca_path, :cert, :key
    attr_reader :req, :debug_output
    def initialize
      @started, @finished = 0, 0
      @address, @port = 'example.com', 80
      @use_ssl = false
    end
    def finish
      @finished += 1
      @socket = nil
    end
    def finished?
      @finished >= 1
    end
    def pipeline requests, &block
      requests.map { |r| r.path }
    end
    def reset?
      @started == @finished + 1
    end
    def set_debug_output io
      @debug_output = io
    end
    def start
      @started += 1
      io = Object.new
      def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end
      @socket = Net::BufferedIO.new io
    end
    def started?
      @started >= 1
    end
    def proxy_address
    end
    def proxy_port
    end
  end

  def basic_connection
    raise "#{@uri} is not HTTP" unless @uri.scheme.downcase == 'http'

    net_http_args = [@uri.hostname, @uri.port, nil, nil, nil, nil]

    connection = Net::HTTP::Persistent::Connection.allocate
    connection.ssl_generation = @http.ssl_generation
    connection.http = BasicConnection.new
    connection.reset

    @http.pool.available.push connection, connection_args: net_http_args

    connection
  end

  def connection uri = @uri
    @uri = uri

    connection = basic_connection
    connection.last_use = Time.now

    def (connection.http).request(req)
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      def r.http_version() '1.1' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    connection
  end

  def ssl_connection
    raise "#{@uri} is not HTTPS" unless @uri.scheme.downcase == 'https'

    net_http_args = [@uri.hostname, @uri.port, nil, nil, nil, nil]

    connection = Net::HTTP::Persistent::Connection.allocate
    connection.ssl_generation = @http.ssl_generation
    connection.http = BasicConnection.new
    connection.reset

    @http.pool.available.push connection, connection_args: net_http_args

    connection
  end

  def test_initialize
    assert_nil @http.proxy_uri

    assert_empty @http.no_proxy

    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    ssl_session_exists = OpenSSL::SSL.const_defined? :Session

    assert_equal ssl_session_exists, @http.reuse_ssl_sessions
  end

  def test_initialize_name
    http = Net::HTTP::Persistent.new name: 'name'
    assert_equal 'name', http.name
  end

  def test_initialize_no_ssl_session
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    skip "OpenSSL::SSL::Session does not exist on #{RUBY_PLATFORM}" unless
      OpenSSL::SSL.const_defined? :Session

    ssl_session = OpenSSL::SSL::Session

    OpenSSL::SSL.send :remove_const, :Session

    http = Net::HTTP::Persistent.new

    refute http.reuse_ssl_sessions
  ensure
    OpenSSL::SSL.const_set :Session, ssl_session if ssl_session
  end

  def test_initialize_proxy
    proxy_uri = URI.parse 'http://proxy.example'

    http = Net::HTTP::Persistent.new proxy: proxy_uri

    assert_equal proxy_uri, http.proxy_uri
  end

  def test_ca_file_equals
    @http.ca_file = :ca_file

    assert_equal :ca_file, @http.ca_file
    assert_equal 1, @http.ssl_generation
  end

  def test_ca_path_equals
    @http.ca_path = :ca_path

    assert_equal :ca_path, @http.ca_path
    assert_equal 1, @http.ssl_generation
  end

  def test_cert_store_equals
    @http.cert_store = :cert_store

    assert_equal :cert_store, @http.cert_store
    assert_equal 1, @http.ssl_generation
  end

  def test_certificate_equals
    @http.certificate = :cert

    assert_equal :cert, @http.certificate
    assert_equal 1, @http.ssl_generation
  end

  def test_ciphers_equals
    @http.ciphers = :ciphers

    assert_equal :ciphers, @http.ciphers
    assert_equal 1, @http.ssl_generation
  end

  def test_connection_for
    @http.open_timeout = 123
    @http.read_timeout = 321
    @http.idle_timeout = 42
    @http.max_retries  = 5

    used = @http.connection_for @uri do |c|
      assert_kind_of Net::HTTP, c.http

      assert c.http.started?
      refute c.http.proxy?

      assert_equal 123, c.http.open_timeout
      assert_equal 321, c.http.read_timeout
      assert_equal 42, c.http.keep_alive_timeout
      assert_equal 5, c.http.max_retries if c.http.respond_to?(:max_retries)

      c
    end

    stored = @http.pool.checkout ['example.com', 80, nil, nil, nil, nil]

    assert_same used, stored
  end

  def test_connection_for_cached
    cached = basic_connection
    cached.http.start

    @http.read_timeout = 5

    @http.connection_for @uri do |c|
      assert c.http.started?

      assert_equal 5, c.http.read_timeout

      assert_same cached, c
    end
  end

  def test_connection_for_closed
    cached = basic_connection
    cached.http.start
    if Socket.const_defined? :TCP_NODELAY then
      io = Object.new
      def io.setsockopt(*a) raise IOError, 'closed stream' end
      cached.instance_variable_set :@socket, Net::BufferedIO.new(io)
    end

    @http.connection_for @uri do |c|
      assert c.http.started?

      socket = c.http.instance_variable_get :@socket

      refute_includes socket.io.instance_variables, :@setsockopt
      refute_includes socket.io.instance_variables, '@setsockopt'
    end
  end

  def test_connection_for_debug_output
    io = StringIO.new
    @http.debug_output = io

    @http.connection_for @uri do |c|
      assert c.http.started?
      assert_equal io, c.http.instance_variable_get(:@debug_output)
    end
  end

  def test_connection_for_cached_expire_always
    cached = basic_connection
    cached.http.start
    cached.requests = 10
    cached.last_use = Time.now # last used right now

    @http.idle_timeout = 0

    @http.connection_for @uri do |c|
      assert c.http.started?

      assert_same cached, c

      assert_equal 0, c.requests, 'connection reset due to timeout'
    end
  end

  def test_connection_for_cached_expire_never
    cached = basic_connection
    cached.http.start
    cached.requests = 10
    cached.last_use = Time.now # last used right now

    @http.idle_timeout = nil

    @http.connection_for @uri do |c|
      assert c.http.started?

      assert_same cached, c

      assert_equal 10, c.requests, 'connection reset despite no timeout'
    end
  end

  def test_connection_for_cached_expired
    cached = basic_connection
    cached.http.start
    cached.requests = 10
    cached.last_use = Time.now - 3600

    @http.connection_for @uri do |c|
      assert c.http.started?

      assert_same cached, c
      assert_equal 0, cached.requests, 'connection not reset due to timeout'
    end
  end

  def test_connection_for_finished_ssl
    skip 'Broken on Windows' if Gem.win_platform?
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'https://example.com/path'

    @http.connection_for uri do |c|
      assert c.http.started?
      assert c.http.use_ssl?

      @http.finish c

      refute c.http.started?
    end

    @http.connection_for uri do |c2|
      assert c2.http.started?
    end
  end

  def test_connection_for_ipv6
    @http.connection_for @uri_v6 do |c|
      assert_equal '2001:db8::1', c.http.address
    end
  end

  def test_connection_for_host_down
    c = basic_connection
    def (c.http).start; raise Errno::EHOSTDOWN end
    def (c.http).started?; false end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.connection_for @uri do end
    end

    assert_equal 'host down: example.com:80', e.message
  end

  def test_connection_for_http_class_with_fakeweb
    Object.send :const_set, :FakeWeb, nil

    @http.connection_for @uri do |c|
      assert_instance_of Net::HTTP, c.http
    end
  ensure
    if Object.const_defined?(:FakeWeb) then
      Object.send :remove_const, :FakeWeb
    end
  end

  def test_connection_for_http_class_with_webmock
    Object.send :const_set, :WebMock, nil
    @http.connection_for @uri do |c|
      assert_instance_of Net::HTTP, c.http
    end
  ensure
    if Object.const_defined?(:WebMock) then
      Object.send :remove_const, :WebMock
    end
  end

  def test_connection_for_http_class_with_artifice
    Object.send :const_set, :Artifice, nil
    @http.connection_for @uri do |c|
      assert_instance_of Net::HTTP, c.http
    end
  ensure
    if Object.const_defined?(:Artifice) then
      Object.send :remove_const, :Artifice
    end
  end

  def test_connection_for_name
    http = Net::HTTP::Persistent.new name: 'name'
    uri = URI.parse 'http://example/'

    http.connection_for uri do |c|
      assert c.http.started?
    end
  end

  def test_connection_for_proxy
    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new proxy: uri

    used = http.connection_for @uri do |c|
      assert c.http.started?
      assert c.http.proxy?

      c
    end

    stored = http.pool.checkout ['example.com', 80,
                                 'proxy.example', 80,
                                 'johndoe', 'muffins']

    assert_same used, stored
  end

  def test_connection_for_proxy_unescaped
    uri = URI.parse 'http://proxy.example'
    uri.user = 'john%40doe'
    uri.password = 'muf%3Afins'
    uri.freeze

    http = Net::HTTP::Persistent.new proxy: uri

    http.connection_for @uri do end

    stored = http.pool.checkout ['example.com', 80,
                                 'proxy.example', 80,
                                 'john@doe', 'muf:fins']

    assert stored
  end

  def test_connection_for_proxy_host_down
    Net::HTTP.use_connect :host_down_connect

    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new proxy: uri

    e = assert_raises Net::HTTP::Persistent::Error do
      http.connection_for @uri do end
    end

    assert_equal 'host down: proxy.example:80', e.message
  end

  def test_connection_for_proxy_refused
    Net::HTTP.use_connect :refused_connect

    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new proxy: uri

    e = assert_raises Net::HTTP::Persistent::Error do
      http.connection_for @uri do end
    end

    assert_equal 'connection refused: proxy.example:80', e.message
  end

  def test_connection_for_no_proxy
    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'
    uri.query    = 'no_proxy=example.com'

    http = Net::HTTP::Persistent.new proxy: uri

    http.connection_for @uri do |c|
      assert c.http.started?
      refute c.http.proxy?
    end

    stored = http.pool.checkout ['example.com', 80]

    assert stored
  end

  def test_connection_for_no_proxy_from_env
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost, example.com,'
    ENV['proxy_user'] = 'johndoe'
    ENV['proxy_password'] = 'muffins'

    http = Net::HTTP::Persistent.new proxy: :ENV

    http.connection_for @uri do |c|
      assert c.http.started?
      refute c.http.proxy?
      refute c.http.proxy_from_env?
    end
  end

  def test_connection_for_refused
    Net::HTTP.use_connect :refused_connect

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.connection_for @uri do end
    end

    assert_equal 'connection refused: example.com:80', e.message
  end

  def test_connection_for_ssl
    skip 'Broken on Windows' if Gem.win_platform?
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'https://example.com/path'

    @http.connection_for uri do |c|
      assert c.http.started?
      assert c.http.use_ssl?
    end
  end

  def test_connection_for_ssl_cached
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI.parse 'https://example.com/path'

    cached = ssl_connection

    @http.connection_for @uri do |c|
      assert_same cached, c
    end
  end

  def test_connection_for_ssl_cached_reconnect
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI.parse 'https://example.com/path'

    cached = ssl_connection

    ssl_generation = @http.ssl_generation

    @http.reconnect_ssl

    @http.connection_for @uri do |c|
      assert_same cached, c
      refute_equal ssl_generation, c.ssl_generation
    end
  end

  def test_connection_for_ssl_case
    skip 'Broken on Windows' if Gem.win_platform?
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'HTTPS://example.com/path'
    @http.connection_for uri do |c|
      assert c.http.started?
      assert c.http.use_ssl?
    end
  end

  def test_connection_for_timeout
    cached = basic_connection
    cached.http.start
    cached.requests = 10
    cached.last_use = Time.now - 6

    @http.connection_for @uri do |c|
      assert c.http.started?
      assert_equal 0, c.requests

      assert_same cached, c
    end
  end

  def test_escape
    assert_nil @http.escape nil

    assert_equal '+%3F', @http.escape(' ?')
  end

  def test_unescape
    assert_nil @http.unescape nil

    assert_equal ' ?', @http.unescape('+%3F')
  end

  def test_expired_eh
    skip 'Broken on Windows' if Gem.win_platform?
    c = basic_connection
    c.requests = 0
    c.last_use = Time.now - 11

    @http.idle_timeout = 0
    assert @http.expired? c

    @http.idle_timeout = 10
    assert @http.expired? c

    @http.idle_timeout = 11
    assert @http.expired? c

    @http.idle_timeout = 12
    refute @http.expired? c

    @http.idle_timeout = nil
    refute @http.expired? c
  end

  def test_expired_due_to_max_requests
    c = basic_connection
    c.requests = 0
    c.last_use = Time.now

    refute @http.expired? c

    c.requests = 10
    refute @http.expired? c

    @http.max_requests = 10
    assert @http.expired? c

    c.requests = 9
    refute @http.expired? c
  end

  def test_finish
    c = basic_connection
    c.requests = 5
    c.http.instance_variable_set(:@last_communicated, Process.clock_gettime(Process::CLOCK_MONOTONIC))

    @http.finish c

    refute c.http.started?
    assert c.http.finished?

    assert_equal 0, c.requests
    assert_equal Net::HTTP::Persistent::EPOCH, c.last_use
    assert_nil c.http.instance_variable_get(:@last_communicated)
  end

  def test_finish_io_error
    c = basic_connection
    def (c.http).finish; @finished += 1; raise IOError end
    c.requests = 5

    @http.finish c

    refute c.http.started?
    assert c.http.finished?
  end

  def test_finish_ssl_no_session_reuse
    http = Net::HTTP.new 'localhost', 443, ssl: true
    http.instance_variable_set :@ssl_session, :something

    c = Net::HTTP::Persistent::Connection.allocate
    c.instance_variable_set :@http, http

    @http.reuse_ssl_sessions = false

    @http.finish c

    assert_nil c.http.instance_variable_get :@ssl_session
  end

  def test_http_version
    assert_nil @http.http_version @uri

    connection

    @http.request @uri

    assert_equal '1.1', @http.http_version(@uri)
  end

  def test_http_version_IPv6
    assert_nil @http.http_version @uri_v6

    connection @uri_v6

    @http.request @uri_v6

    assert_equal '1.1', @http.http_version(@uri_v6)
  end

  def test_max_retries_equals
    @http.max_retries = 5

    assert_equal 5, @http.max_retries
    assert_equal 1, @http.generation
  end

  def test_normalize_uri
    assert_equal 'http://example',  @http.normalize_uri('example')
    assert_equal 'http://example',  @http.normalize_uri('http://example')
    assert_equal 'https://example', @http.normalize_uri('https://example')
  end

  def test_override_haeders
    assert_empty @http.override_headers

    @http.override_headers['User-Agent'] = 'MyCustomAgent'

    expected = { 'User-Agent' => 'MyCustomAgent' }

    assert_equal expected, @http.override_headers
  end

  def test_pipeline
    skip 'net-http-pipeline not installed' unless defined?(Net::HTTP::Pipeline)

    cached = basic_connection
    cached.http.start

    requests = [
      Net::HTTP::Get.new((@uri + '1').request_uri),
      Net::HTTP::Get.new((@uri + '2').request_uri),
    ]

    responses = @http.pipeline @uri, requests

    assert_equal 2, responses.length
    assert_equal '/1', responses.first
    assert_equal '/2', responses.last
  end

  def test_private_key_equals
    @http.private_key = :private_key

    assert_equal :private_key, @http.private_key
    assert_equal 1, @http.ssl_generation
  end

  def test_proxy_equals_env
    ENV['http_proxy'] = 'proxy.example'

    @http.proxy = :ENV

    assert_equal URI.parse('http://proxy.example'), @http.proxy_uri

    assert_equal 1, @http.generation, 'generation'
    assert_equal 1, @http.ssl_generation, 'ssl_generation'
  end

  def test_proxy_equals_nil
    @http.proxy = nil

    assert_nil @http.proxy_uri

    assert_equal 1, @http.generation, 'generation'
    assert_equal 1, @http.ssl_generation, 'ssl_generation'
  end

  def test_proxy_equals_uri
    proxy_uri = URI.parse 'http://proxy.example'

    @http.proxy = proxy_uri

    assert_equal proxy_uri, @http.proxy_uri
  end

  def test_proxy_equals_uri_IPv6
    proxy_uri = @uri_v6

    @http.proxy = proxy_uri

    assert_equal proxy_uri, @http.proxy_uri
  end

  def test_proxy_from_env
    ENV['http_proxy']      = 'proxy.example'
    ENV['http_proxy_user'] = 'johndoe'
    ENV['http_proxy_pass'] = 'muffins'
    ENV['NO_PROXY']        = 'localhost,example.com'

    uri = @http.proxy_from_env

    expected = URI.parse 'http://proxy.example'
    expected.user     = 'johndoe'
    expected.password = 'muffins'
    expected.query    = 'no_proxy=localhost%2Cexample.com'

    assert_equal expected, uri
  end

  def test_proxy_from_env_lower
    ENV['http_proxy']      = 'proxy.example'
    ENV['http_proxy_user'] = 'johndoe'
    ENV['http_proxy_pass'] = 'muffins'
    ENV['no_proxy']        = 'localhost,example.com'

    uri = @http.proxy_from_env

    expected = URI.parse 'http://proxy.example'
    expected.user     = 'johndoe'
    expected.password = 'muffins'
    expected.query    = 'no_proxy=localhost%2Cexample.com'

    assert_equal expected, uri
  end

  def test_proxy_from_env_nil
    uri = @http.proxy_from_env

    assert_nil uri

    ENV['http_proxy'] = ''

    uri = @http.proxy_from_env

    assert_nil uri
  end

  def test_proxy_from_env_no_proxy_star
    uri = @http.proxy_from_env

    assert_nil uri

    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = '*'

    uri = @http.proxy_from_env

    assert_nil uri
  end

  def test_proxy_bypass
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,example.com:80'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'localhost', 80
    assert @http.proxy_bypass? 'localhost', 443
    assert @http.proxy_bypass? 'LOCALHOST', 80
    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.com', 443
    assert @http.proxy_bypass? 'www.example.com', 80
    refute @http.proxy_bypass? 'www.example.com', 443
    assert @http.proxy_bypass? 'endingexample.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_space
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost, example.com'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_trailing
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,example.com,'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_double_comma
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,,example.com'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_reconnect
    result = @http.reconnect

    assert_equal 1, result
  end

  def test_reconnect_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI 'https://example.com'
    now = Time.now

    ssl_http = ssl_connection

    def (ssl_http.http).finish
      @started = 0
    end

    used1 = @http.connection_for @uri do |c|
      c.requests = 1
      c.last_use = now
      c
    end

    assert_equal OpenSSL::SSL::VERIFY_PEER, used1.http.verify_mode

    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.reconnect_ssl

    used2 = @http.connection_for @uri do |c|
      c
    end

    assert_same used1, used2

    assert_equal OpenSSL::SSL::VERIFY_NONE, used2.http.verify_mode,
                 'verify mode must change'
    assert_equal 0, used2.requests
    assert_equal Net::HTTP::Persistent::EPOCH, used2.last_use
  end

  def test_requestx
    @http.override_headers['user-agent'] = 'test ua'
    @http.headers['accept'] = 'text/*'
    c = connection

    res = @http.request @uri
    req = c.http.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path

    assert_equal 'test ua',    req['user-agent']
    assert_match %r%text/\*%,  req['accept']

    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    # There's some roounding issue on jruby preventing this from passing
    unless RUBY_PLATFORM == "java"
      assert_in_delta Time.now, c.last_use
    end

    assert_equal 1, c.requests
  end

  def test_request_block
    @http.headers['user-agent'] = 'test ua'
    c = connection
    body = nil

    res = @http.request @uri do |r|
      body = r.read_body
    end

    req = c.http.req

    assert_kind_of Net::HTTPResponse, res
    refute_nil body

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']
    assert_match %r%test ua%,  req['user-agent']

    assert_equal 1, c.requests
  end

  def test_request_close_1_0
    c = connection

    class << c.http
      remove_method :request
    end

    def (c.http).request req
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      def r.http_version() '1.0' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    request = Net::HTTP::Get.new @uri.request_uri

    res = @http.request @uri, request
    req = c.http.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    assert c.http.finished?
  end

  def test_request_connection_close_request
    c = connection

    request = Net::HTTP::Get.new @uri.request_uri
    request['connection'] = 'close'

    res = @http.request @uri, request
    req = c.http.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'close',      req['connection']
    assert_nil req['keep-alive']

    assert c.http.finished?
  end

  def test_request_connection_close_response
    c = connection

    class << c.http
      remove_method :request
    end

    def (c.http).request req
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      r['connection'] = 'close'
      def r.http_version() '1.1' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    request = Net::HTTP::Get.new @uri.request_uri

    res = @http.request @uri, request
    req = c.http.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    assert c.http.finished?
  end

  def test_request_exception
    c = basic_connection
    def (c.http).request(*a)
      raise Exception, "very bad things happened"
    end

    assert_raises Exception do
      @http.request @uri
    end

    assert_equal 0, c.requests
    assert c.http.finished?
  end

  def test_request_invalid
    c = basic_connection
    def (c.http).request(*a) raise Errno::EINVAL, "write" end

    e = assert_raises Errno::EINVAL do
      @http.request @uri
    end

    assert_equal 0, c.requests
    assert_match %r%Invalid argument - write%, e.message
  end

  def test_request_post
    c = connection

    post = Net::HTTP::Post.new @uri.path

    @http.request @uri, post
    req = c.http.req

    assert_same post, req
  end

  def test_request_setup
    @http.override_headers['user-agent'] = 'test ua'
    @http.headers['accept'] = 'text/*'

    input = Net::HTTP::Post.new '/path'

    req = @http.request_setup input

    assert_same input,         req
    assert_equal '/path',      req.path

    assert_equal 'test ua',    req['user-agent']
    assert_match %r%text/\*%,  req['accept']

    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']
  end

  def test_request_string
    @http.override_headers['user-agent'] = 'test ua'
    @http.headers['accept'] = 'text/*'
    c = connection

    res = @http.request @uri.to_s
    req = c.http.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path

    assert_equal 1, c.requests
  end

  def test_request_setup_uri
    uri = @uri + '?a=b'

    req = @http.request_setup uri

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path?a=b',  req.path
  end

  def test_reset
    c = basic_connection
    c.http.start
    c.last_use = Time.now
    c.requests  = 5

    @http.reset c

    assert c.http.started?
    assert c.http.finished?
    assert c.http.reset?
    assert_equal 0, c.requests
    assert_equal Net::HTTP::Persistent::EPOCH, c.last_use
  end

  def test_reset_host_down
    c = basic_connection
    c.last_use = Time.now
    def (c.http).start; raise Errno::EHOSTDOWN end
    c.requests = 5

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.reset c
    end

    assert_match %r%host down%, e.message
    assert_match __FILE__, e.backtrace.first
  end

  def test_reset_io_error
    c = basic_connection
    c.last_use = Time.now
    c.requests = 5

    @http.reset c

    assert c.http.started?
    assert c.http.finished?
  end

  def test_reset_refused
    c = basic_connection
    c.last_use = Time.now
    def (c.http).start; raise Errno::ECONNREFUSED end
    c.requests = 5

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.reset c
    end

    assert_match %r%connection refused%, e.message
    assert_match __FILE__, e.backtrace.first
  end

  def test_shutdown
    c = connection

    orig = @http
    @http = Net::HTTP::Persistent.new name: 'name'
    c2 = connection

    orig.shutdown

    @http = orig

    assert c.http.finished?, 'last-generation connection must be finished'
    refute c2.http.finished?, 'present generation connection must not be finished'
  end

  def test_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_callback = :callback
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, c.verify_mode
    assert_kind_of OpenSSL::X509::Store,    c.cert_store
    assert_nil c.verify_callback
  end

  def test_ssl_ca_file
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.ca_file = 'ca_file'
    @http.verify_callback = :callback
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, c.verify_mode
    assert_equal :callback, c.verify_callback
  end

  def test_ssl_ca_path
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.ca_path = 'ca_path'
    @http.verify_callback = :callback
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, c.verify_mode
    assert_equal :callback, c.verify_callback
  end

  def test_ssl_cert_store
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    store = OpenSSL::X509::Store.new
    @http.cert_store = store

    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal store, c.cert_store
  end

  def test_ssl_cert_store_default
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert c.cert_store
  end

  def test_ssl_certificate
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.certificate = :cert
    @http.private_key = :key
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal :cert, c.cert
    assert_equal :key,  c.key
  end

  def test_ssl_verify_mode
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_NONE, c.verify_mode
  end

  def test_ssl_warning
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    begin
      orig_verify_peer = OpenSSL::SSL::VERIFY_PEER
      OpenSSL::SSL.send :remove_const, :VERIFY_PEER
      OpenSSL::SSL.send :const_set, :VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE

      c = Net::HTTP.new 'localhost', 80

      out, err = capture_io do
        @http.ssl c
      end

      assert_empty out

      assert_match %r%localhost:80%, err
      assert_match %r%I_KNOW_THAT_OPENSSL%, err

      Object.send :const_set, :I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG, nil

      assert_silent do
        @http.ssl c
      end
    ensure
      OpenSSL::SSL.send :remove_const, :VERIFY_PEER
      OpenSSL::SSL.send :const_set, :VERIFY_PEER, orig_verify_peer
      if Object.const_defined?(:I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG) then
        Object.send :remove_const, :I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG
      end
    end
  end

  def test_ssl_timeout_equals
    @http.ssl_timeout = :ssl_timeout

    assert_equal :ssl_timeout, @http.ssl_timeout
    assert_equal 1, @http.ssl_generation
  end

  def test_ssl_version_equals
    @http.ssl_version = :ssl_version

    assert_equal :ssl_version, @http.ssl_version
    assert_equal 1, @http.ssl_generation
  end

  def test_min_version_equals
    @http.min_version = :min_version

    assert_equal :min_version, @http.min_version
    assert_equal 1, @http.ssl_generation
  end

  def test_max_version_equals
    @http.max_version = :max_version

    assert_equal :max_version, @http.max_version
    assert_equal 1, @http.ssl_generation
  end

  def test_start
    c = basic_connection
    c = c.http

    @http.socket_options << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]
    @http.debug_output = $stderr
    @http.open_timeout = 6

    @http.start c

    assert_equal $stderr, c.debug_output
    assert_equal 6,       c.open_timeout

    socket = c.instance_variable_get :@socket

    expected = []
    expected << [Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1] if
      Socket.const_defined? :TCP_NODELAY
    expected << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]

    assert_equal expected, socket.io.instance_variable_get(:@setsockopts)
  end

  def test_verify_callback_equals
    @http.verify_callback = :verify_callback

    assert_equal :verify_callback, @http.verify_callback
    assert_equal 1, @http.ssl_generation
  end

  def test_verify_depth_equals
    @http.verify_depth = :verify_depth

    assert_equal :verify_depth, @http.verify_depth
    assert_equal 1, @http.ssl_generation
  end

  def test_verify_mode_equals
    @http.verify_mode = :verify_mode

    assert_equal :verify_mode, @http.verify_mode
    assert_equal 1, @http.ssl_generation
  end

  def test_connection_pool_after_fork
    # ConnectionPool 2.4+ calls `checkin(force: true)` after fork
    @http.pool.checkin(force: true)

    @http.pool.checkout ['example.com', 80, nil, nil, nil, nil]
    @http.pool.checkin(force: true)
    @http.pool.reload do |connection|
      connection.close
    end
  end
end

