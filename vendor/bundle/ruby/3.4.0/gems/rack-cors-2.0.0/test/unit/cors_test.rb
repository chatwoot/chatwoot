# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'mocha/setup'
require 'rack/cors'
require 'ostruct'

Rack::Test::Session.class_eval do
  unless defined? :options
    def options(uri, params = {}, env = {}, &block)
      env = env_for(uri, env.merge(method: 'OPTIONS', params: params))
      process_request(uri, env, &block)
    end
  end
end

Rack::Test::Methods.class_eval do
  def_delegator :current_session, :options
end

module MiniTest::Assertions
  def assert_cors_success(response)
    assert !response.headers['Access-Control-Allow-Origin'].nil?, 'Expected a successful CORS response'
  end

  def assert_not_cors_success(response)
    assert response.headers['Access-Control-Allow-Origin'].nil?, 'Expected a failed CORS response'
  end
end

class CaptureResult
  def initialize(app, options = {})
    @app = app
    @result_holder = options[:holder]
  end

  def call(env)
    response = @app.call(env)
    @result_holder.cors_result = env[Rack::Cors::RACK_CORS]
    response
  end
end

class FakeProxy
  def initialize(app, _options = {})
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers['vary'] = %w[Origin User-Agent]
    [status, headers, body]
  end
end

Rack::MockResponse.infect_an_assertion :assert_cors_success, :must_render_cors_success, :only_one_argument
Rack::MockResponse.infect_an_assertion :assert_not_cors_success, :wont_render_cors_success, :only_one_argument

describe Rack::Cors do
  include Rack::Test::Methods

  attr_accessor :cors_result

  def load_app(name, options = {})
    test = self
    Rack::Builder.new do
      use CaptureResult, holder: test
      eval File.read(File.dirname(__FILE__) + "/#{name}.ru")
      use FakeProxy if options[:proxy]
      map('/') do
        run(lambda do |_env|
          [200, { 'Content-Type' => 'text/html' }, ['success']]
        end)
      end
    end
  end

  let(:app) { load_app('test') }

  it 'should support simple CORS request' do
    successful_cors_request
    _(cors_result).must_be :hit
  end

  it "should not return CORS headers if Origin header isn't present" do
    get '/'
    _(last_response).wont_render_cors_success
    _(cors_result).wont_be :hit
  end

  it 'should support OPTIONS CORS request' do
    successful_cors_request '/options', method: :options
  end

  it 'should support regex origins configuration' do
    successful_cors_request origin: 'http://192.168.0.1:1234'
  end

  it 'should support subdomain example' do
    successful_cors_request origin: 'http://subdomain.example.com'
  end

  it 'should support proc origins configuration' do
    successful_cors_request '/proc-origin', origin: 'http://10.10.10.10:3000'
  end

  it 'should support lambda origin configuration' do
    successful_cors_request '/lambda-origin', origin: 'http://10.10.10.10:3000'
  end

  it 'should support proc origins configuration (inverse)' do
    cors_request '/proc-origin', origin: 'http://bad.guy'
    _(last_response).wont_render_cors_success
  end

  it 'should not mix up path rules across origins' do
    header 'Origin', 'http://10.10.10.10:3000'
    get '/' # / is configured in a separate rule block
    _(last_response).wont_render_cors_success
  end

  it 'should support alternative X-Origin header' do
    header 'X-Origin', 'http://localhost:3000'
    get '/'
    _(last_response).must_render_cors_success
  end

  it 'should support expose header configuration' do
    successful_cors_request '/expose_single_header'
    _(last_response.headers['Access-Control-Expose-Headers']).must_equal 'expose-test'
  end

  it 'should support expose multiple header configuration' do
    successful_cors_request '/expose_multiple_headers'
    _(last_response.headers['Access-Control-Expose-Headers']).must_equal 'expose-test-1, expose-test-2'
  end

  # Explanation: http://www.fastly.com/blog/best-practices-for-using-the-vary-header/
  it "should add Vary header if resource matches even if Origin header isn't present" do
    get '/'
    _(last_response).wont_render_cors_success
    _(last_response.headers['Vary']).must_equal 'Origin'
  end

  it 'should add Vary header based on :vary option' do
    successful_cors_request '/vary_test'
    _(last_response.headers['Vary']).must_equal 'Origin, Host'
  end

  it 'decode URL and resolve paths before resource matching' do
    header 'Origin', 'http://localhost:3000'
    get '/public/a/..%2F..%2Fprivate/stuff'
    _(last_response).wont_render_cors_success
  end

  describe 'with upstream Vary headers' do
    let(:app) { load_app('test', { proxy: true }) }

    it 'should add to them' do
      successful_cors_request '/vary_test'
      _(last_response.headers['Vary']).must_equal 'Origin, User-Agent, Host'
    end
  end

  it 'should add Vary header if Access-Control-Allow-Origin header was added and if it is specific' do
    successful_cors_request '/', origin: 'http://192.168.0.3:8080'
    _(last_response.headers['Access-Control-Allow-Origin']).must_equal 'http://192.168.0.3:8080'
    _(last_response.headers['Vary']).wont_be_nil
  end

  it 'should add Vary header even if Access-Control-Allow-Origin header was added and it is generic (*)' do
    successful_cors_request '/public_without_credentials', origin: 'http://192.168.1.3:8080'
    _(last_response.headers['Access-Control-Allow-Origin']).must_equal '*'
    _(last_response.headers['Vary']).must_equal 'Origin'
  end

  it 'should support multi allow configurations for the same resource' do
    successful_cors_request '/multi-allow-config', origin: 'http://mucho-grande.com'
    _(last_response.headers['Access-Control-Allow-Origin']).must_equal 'http://mucho-grande.com'
    _(last_response.headers['Vary']).must_equal 'Origin'

    successful_cors_request '/multi-allow-config', origin: 'http://192.168.1.3:8080'
    _(last_response.headers['Access-Control-Allow-Origin']).must_equal '*'
    _(last_response.headers['Vary']).must_equal 'Origin'
  end

  it 'should not return CORS headers on OPTIONS request if Access-Control-Allow-Origin is not present' do
    options '/get-only'
    _(last_response.headers['Access-Control-Allow-Origin']).must_be_nil
  end

  it 'should not apply CORS headers if it does not match conditional on resource' do
    header 'Origin', 'http://192.168.0.1:1234'
    get '/conditional'
    _(last_response).wont_render_cors_success
  end

  it 'should apply CORS headers if it does match conditional on resource' do
    header 'X-OK', '1'
    successful_cors_request '/conditional', origin: 'http://192.168.0.1:1234'
  end

  it 'should not allow everything if Origin is configured as blank string' do
    cors_request '/blank-origin', origin: 'http://example.net'
    _(last_response).wont_render_cors_success
  end

  it 'should not allow credentials for public resources' do
    successful_cors_request '/public'
    _(last_response.headers['Access-Control-Allow-Credentials']).must_be_nil
  end

  describe 'logging' do
    it 'should not log debug messages if debug option is false' do
      app = mock
      app.stubs(:call).returns(200, {}, [''])

      logger = mock
      logger.expects(:debug).never

      cors = Rack::Cors.new(app, debug: false, logger: logger) {}
      cors.send(:debug, {}, 'testing')
    end

    it 'should log debug messages if debug option is true' do
      app = mock
      app.stubs(:call).returns(200, {}, [''])

      logger = mock
      logger.expects(:debug)

      cors = Rack::Cors.new(app, debug: true, logger: logger) {}
      cors.send(:debug, {}, 'testing')
    end

    it 'should use rack.logger if available' do
      app = mock
      app.stubs(:call).returns([200, {}, ['']])

      logger = mock
      logger.expects(:debug).at_least_once

      cors = Rack::Cors.new(app, debug: true) {}
      cors.call({ 'rack.logger' => logger, 'HTTP_ORIGIN' => 'test.com' })
    end

    it 'should use logger proc' do
      app = mock
      app.stubs(:call).returns([200, {}, ['']])

      logger = mock
      logger.expects(:debug)

      cors = Rack::Cors.new(app, debug: true, logger: proc { logger }) {}
      cors.call({ 'HTTP_ORIGIN' => 'test.com' })
    end

    describe 'with Rails setup' do
      after do
        ::Rails.logger = nil if defined?(::Rails)
      end

      it 'should use Rails.logger if available' do
        app = mock
        app.stubs(:call).returns([200, {}, ['']])

        logger = mock
        logger.expects(:debug)

        ::Rails = OpenStruct.new(logger: logger)

        cors = Rack::Cors.new(app, debug: true) {}
        cors.call({ 'HTTP_ORIGIN' => 'test.com' })
      end
    end

    it 'should use Logger if none is set' do
      app = mock
      app.stubs(:call).returns([200, {}, ['']])

      logger = mock
      Logger.expects(:new).returns(logger)
      logger.expects(:tap).returns(logger)
      logger.expects(:debug)

      cors = Rack::Cors.new(app, debug: true) {}
      cors.call({ 'HTTP_ORIGIN' => 'test.com' })
    end
  end

  describe 'preflight requests' do
    it 'should fail if origin is invalid' do
      preflight_request('http://allyourdataarebelongtous.com', '/')
      _(last_response).wont_render_cors_success
      _(cors_result).wont_be :hit
      _(cors_result).must_be :preflight
    end

    it 'should fail if Access-Control-Request-Method is not allowed' do
      preflight_request('http://localhost:3000', '/get-only', method: :post)
      _(last_response).wont_render_cors_success
      _(cors_result.miss_reason).must_equal Rack::Cors::Result::MISS_DENY_METHOD
      _(cors_result).wont_be :hit
      _(cors_result).must_be :preflight
    end

    it 'should fail if header is not allowed' do
      preflight_request('http://localhost:3000', '/single_header', headers: 'Fooey')
      _(last_response).wont_render_cors_success
      _(cors_result.miss_reason).must_equal Rack::Cors::Result::MISS_DENY_HEADER
      _(cors_result).wont_be :hit
      _(cors_result).must_be :preflight
    end

    it 'should allow any header if headers = :any' do
      preflight_request('http://localhost:3000', '/', headers: 'Fooey')
      _(last_response).must_render_cors_success
    end

    it 'should allow any method if methods = :any' do
      preflight_request('http://localhost:3000', '/', methods: :any)
      _(last_response).must_render_cors_success
    end

    it 'allows PATCH method' do
      preflight_request('http://localhost:3000', '/', methods: [:patch])
      _(last_response).must_render_cors_success
    end

    it 'should allow header case insensitive match' do
      preflight_request('http://localhost:3000', '/single_header', headers: 'X-Domain-Token')
      _(last_response).must_render_cors_success
    end

    it 'should allow multiple headers match' do
      # Webkit style
      preflight_request('http://localhost:3000', '/two_headers', headers: 'X-Requested-With, X-Domain-Token')
      _(last_response).must_render_cors_success

      # Gecko style
      preflight_request('http://localhost:3000', '/two_headers', headers: 'x-requested-with,x-domain-token')
      _(last_response).must_render_cors_success
    end

    it "should allow '*' origins to allow any origin" do
      preflight_request('http://locohost:3000', '/public')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).must_equal '*'
    end

    it "should allow '/<path>/' resource if match pattern is /<path>/*" do
      preflight_request('http://localhost:3000', '/wildcard/')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).wont_equal nil
    end

    it "should allow '/<path>' resource if match pattern is /<path>/*" do
      preflight_request('http://localhost:3000', '/wildcard')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).wont_equal nil
    end

    it "should allow '*' origin to allow any origin, and set '*' if no credentials required" do
      preflight_request('http://locohost:3000', '/public_without_credentials')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).must_equal '*'
    end

    it 'should return "file://" as header with "file://" as origin' do
      preflight_request('file://', '/')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).must_equal 'file://'
    end

    it 'supports custom protocols in origin' do
      preflight_request('custom-protocol://abcdefg', '/')
      _(last_response).must_render_cors_success
      _(last_response.headers['Access-Control-Allow-Origin']).must_equal 'custom-protocol://abcdefg'
    end

    describe '' do
      let(:app) do
        test = self
        Rack::Builder.new do
          use CaptureResult, holder: test
          use Rack::Cors, debug: true, logger: Logger.new(StringIO.new) do
            allow do
              origins '*'
              resource '/', methods: :post
            end
          end
          map('/') do
            run ->(_env) { [500, {}, ['FAIL!']] }
          end
        end
      end

      it 'should not send failed preflight requests thru the app' do
        preflight_request('http://localhost', '/', method: :unsupported)
        _(last_response).wont_render_cors_success
        _(last_response.status).must_equal 200
        _(cors_result).must_be :preflight
        _(cors_result).wont_be :hit
        _(cors_result.miss_reason).must_equal Rack::Cors::Result::MISS_DENY_METHOD
      end
    end
  end

  describe 'with insecure configuration' do
    let(:app) { load_app('insecure') }

    it 'should raise an error' do
      _(proc { cors_request '/public' }).must_raise Rack::Cors::Resource::CorsMisconfigurationError
    end
  end

  describe 'with non HTTP config' do
    let(:app) { load_app('non_http') }

    it 'should support non http/https origins' do
      successful_cors_request '/public', origin: 'content://com.company.app'
    end
  end

  describe 'Rack::Lint' do
    def app
      @app ||= Rack::Builder.new do
        use Rack::Cors
        use Rack::Lint
        run ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['hello']] }
      end
    end

    it 'is lint-compliant with non-CORS request' do
      get '/'
      _(last_response.status).must_equal 200
    end
  end

  describe 'with app overriding CORS header' do
    let(:app) do
      Rack::Builder.new do
        use Rack::Cors, debug: true, logger: Logger.new(StringIO.new) do
          allow do
            origins '*'
            resource '/'
          end
        end
        map('/') do
          run ->(_env) { [200, { 'Access-Control-Allow-Origin' => 'http://foo.net' }, ['success']] }
        end
      end
    end

    it 'should return app header' do
      successful_cors_request origin: 'http://example.net'
      _(last_response.headers['Access-Control-Allow-Origin']).must_equal 'http://foo.net'
    end

    it 'should return original headers if in debug' do
      successful_cors_request origin: 'http://example.net'
      _(last_response.headers['X-Rack-CORS-Original-Access-Control-Allow-Origin']).must_equal '*'
    end
  end

  describe 'with headers set to nil' do
    let(:app) do
      Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '/', headers: nil
          end
        end
        map('/') do
          run ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['hello']] }
        end
      end
    end

    it 'should succeed with CORS simple headers' do
      preflight_request('http://localhost:3000', '/', headers: 'Accept')
      _(last_response).must_render_cors_success
    end
  end

  describe 'with custom allowed headers' do
    let(:app) do
      Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '/', headers: []
          end
        end
        map('/') do
          run ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['hello']] }
        end
      end
    end

    it 'should succeed with CORS simple headers' do
      preflight_request('http://localhost:3000', '/', headers: 'Accept')
      _(last_response).must_render_cors_success
      preflight_request('http://localhost:3000', '/', headers: 'Accept-Language')
      _(last_response).must_render_cors_success
      preflight_request('http://localhost:3000', '/', headers: 'Content-Type')
      _(last_response).must_render_cors_success
      preflight_request('http://localhost:3000', '/', headers: 'Content-Language')
      _(last_response).must_render_cors_success
    end
  end

  protected

  def cors_request(*args)
    path = args.first.is_a?(String) ? args.first : '/'

    opts = { method: :get, origin: 'http://localhost:3000' }
    opts.merge! args.last if args.last.is_a?(Hash)

    header 'origin', opts[:origin]
    current_session.__send__ opts[:method], path, {}, test: self
  end

  def successful_cors_request(*args)
    cors_request(*args)
    _(last_response).must_render_cors_success
  end

  def preflight_request(origin, path, opts = {})
    header 'Origin', origin
    unless opts.key?(:method) && opts[:method].nil?
      header 'Access-Control-Request-Method', opts[:method] ? opts[:method].to_s.upcase : 'GET'
    end
    header 'Access-Control-Request-Headers', opts[:headers] if opts[:headers]
    options path
  end
end
