# frozen_string_literal: true

require 'stringio'
require 'logger'

RSpec.describe Faraday::Response::Logger do
  let(:string_io) { StringIO.new }
  let(:logger) { Logger.new(string_io) }
  let(:logger_options) { {} }
  let(:conn) do
    rubbles = ['Barney', 'Betty', 'Bam Bam']

    Faraday.new do |b|
      b.response :logger, logger, logger_options do |logger|
        logger.filter(/(soylent green is) (.+)/, '\1 tasty')
        logger.filter(/(api_key:).*"(.+)."/, '\1[API_KEY]')
        logger.filter(/(password)=(.+)/, '\1=[HIDDEN]')
      end
      b.adapter :test do |stubs|
        stubs.get('/hello') { [200, { 'Content-Type' => 'text/html' }, 'hello'] }
        stubs.post('/ohai') { [200, { 'Content-Type' => 'text/html' }, 'fred'] }
        stubs.post('/ohyes') { [200, { 'Content-Type' => 'text/html' }, 'pebbles'] }
        stubs.get('/rubbles') { [200, { 'Content-Type' => 'application/json' }, rubbles] }
        stubs.get('/filtered_body') { [200, { 'Content-Type' => 'text/html' }, 'soylent green is people'] }
        stubs.get('/filtered_headers') { [200, { 'Content-Type' => 'text/html' }, 'headers response'] }
        stubs.get('/filtered_params') { [200, { 'Content-Type' => 'text/html' }, 'params response'] }
        stubs.get('/filtered_url') { [200, { 'Content-Type' => 'text/html' }, 'url response'] }
        stubs.get('/connection_failed') { raise Faraday::ConnectionFailed, 'Failed to open TCP connection' }
      end
    end
  end

  before do
    logger.level = Logger::DEBUG
  end

  it 'still returns output' do
    resp = conn.get '/hello', nil, accept: 'text/html'
    expect(resp.body).to eq('hello')
  end

  context 'without configuration' do
    let(:conn) do
      Faraday.new do |b|
        b.response :logger
        b.adapter :test do |stubs|
          stubs.get('/hello') { [200, { 'Content-Type' => 'text/html' }, 'hello'] }
        end
      end
    end

    it 'defaults to stdout' do
      expect(Logger).to receive(:new).with($stdout).and_return(Logger.new(nil))
      conn.get('/hello')
    end
  end

  context 'when logger with program name' do
    let(:logger) { Logger.new(string_io, progname: 'my_best_program') }

    it 'logs with program name' do
      conn.get '/hello'

      expect(string_io.string).to match('-- my_best_program: request:')
      expect(string_io.string).to match('-- my_best_program: response:')
    end
  end

  context 'when logger without program name' do
    it 'logs without program name' do
      conn.get '/hello'

      expect(string_io.string).to match('-- : request:')
      expect(string_io.string).to match('-- : response:')
    end
  end

  context 'with default formatter' do
    let(:formatter) { instance_double(Faraday::Logging::Formatter, request: true, response: true, filter: []) }

    before { allow(Faraday::Logging::Formatter).to receive(:new).and_return(formatter) }

    it 'delegates logging to the formatter' do
      expect(formatter).to receive(:request).with(an_instance_of(Faraday::Env))
      expect(formatter).to receive(:response).with(an_instance_of(Faraday::Env))
      conn.get '/hello'
    end

    context 'when no route' do
      it 'delegates logging to the formatter' do
        expect(formatter).to receive(:request).with(an_instance_of(Faraday::Env))
        expect(formatter).to receive(:exception).with(an_instance_of(Faraday::Adapter::Test::Stubs::NotFound))

        expect { conn.get '/noroute' }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
      end
    end
  end

  context 'with custom formatter' do
    let(:formatter_class) do
      Class.new(Faraday::Logging::Formatter) do
        def request(_env)
          info 'Custom log formatter request'
        end

        def response(_env)
          info 'Custom log formatter response'
        end
      end
    end

    let(:logger_options) { { formatter: formatter_class } }

    it 'logs with custom formatter' do
      conn.get '/hello'

      expect(string_io.string).to match('Custom log formatter request')
      expect(string_io.string).to match('Custom log formatter response')
    end
  end

  it 'logs method and url' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match('GET http:/hello')
  end

  it 'logs status' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match('Status 200')
  end

  it 'does not log error message by default' do
    expect { conn.get '/noroute' }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
    expect(string_io.string).not_to match(%(no stubbed request for get http:/noroute))
  end

  it 'logs request headers by default' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match(%(Accept: "text/html))
  end

  it 'logs response headers by default' do
    conn.get '/hello', nil, accept: 'text/html'
    expect(string_io.string).to match(%(Content-Type: "text/html))
  end

  it 'does not log request body by default' do
    conn.post '/ohai', 'name=Unagi', accept: 'text/html'
    expect(string_io.string).not_to match(%(name=Unagi))
  end

  it 'does not log response body by default' do
    conn.post '/ohai', 'name=Toro', accept: 'text/html'
    expect(string_io.string).not_to match(%(fred))
  end

  it 'logs filter headers' do
    conn.headers = { 'api_key' => 'ABC123' }
    conn.get '/filtered_headers', nil, accept: 'text/html'
    expect(string_io.string).to match(%(api_key:))
    expect(string_io.string).to match(%([API_KEY]))
    expect(string_io.string).not_to match(%(ABC123))
  end

  it 'logs filter url' do
    conn.get '/filtered_url?password=hunter2', nil, accept: 'text/html'
    expect(string_io.string).to match(%([HIDDEN]))
    expect(string_io.string).not_to match(%(hunter2))
  end

  context 'when not logging request headers' do
    let(:logger_options) { { headers: { request: false } } }

    it 'does not log request headers if option is false' do
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).not_to match(%(Accept: "text/html))
    end
  end

  context 'when not logging response headers' do
    let(:logger_options) { { headers: { response: false } } }

    it 'does not log response headers if option is false' do
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).not_to match(%(Content-Type: "text/html))
    end
  end

  context 'when logging request body' do
    let(:logger_options) { { bodies: { request: true } } }

    it 'logs only request body' do
      conn.post '/ohyes', 'name=Tamago', accept: 'text/html'
      expect(string_io.string).to match(%(name=Tamago))
      expect(string_io.string).not_to match(%(pebbles))
    end
  end

  context 'when logging response body' do
    let(:logger_options) { { bodies: { response: true } } }

    it 'logs only response body' do
      conn.post '/ohyes', 'name=Hamachi', accept: 'text/html'
      expect(string_io.string).to match(%(pebbles))
      expect(string_io.string).not_to match(%(name=Hamachi))
    end
  end

  context 'when logging request and response bodies' do
    let(:logger_options) { { bodies: true } }

    it 'logs request and response body' do
      conn.post '/ohyes', 'name=Ebi', accept: 'text/html'
      expect(string_io.string).to match(%(name=Ebi))
      expect(string_io.string).to match(%(pebbles))
    end

    it 'logs response body object' do
      conn.get '/rubbles', nil, accept: 'text/html'
      expect(string_io.string).to match(%([\"Barney\", \"Betty\", \"Bam Bam\"]\n))
    end

    it 'logs filter body' do
      conn.get '/filtered_body', nil, accept: 'text/html'
      expect(string_io.string).to match(%(soylent green is))
      expect(string_io.string).to match(%(tasty))
      expect(string_io.string).not_to match(%(people))
    end
  end

  context 'when bodies are logged by default' do
    before do
      described_class.default_options = { bodies: true }
    end

    it 'logs response body' do
      conn.post '/ohai'
      expect(string_io.string).to match(%(fred))
    end

    after do
      described_class.default_options = { bodies: false }
    end
  end

  context 'when logging errors' do
    let(:logger_options) { { errors: true } }

    it 'logs error message' do
      expect { conn.get '/noroute' }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
      expect(string_io.string).to match(%(no stubbed request for get http:/noroute))
    end
  end

  context 'when logging headers and errors' do
    let(:logger_options) { { headers: true, errors: true } }

    it 'logs error message' do
      expect { conn.get '/connection_failed' }.to raise_error(Faraday::ConnectionFailed)
      expect(string_io.string).to match(%(Failed to open TCP connection))
    end
  end

  context 'when using log_level' do
    let(:logger_options) { { bodies: true, log_level: :debug } }

    it 'logs request/request body on the specified level (debug)' do
      logger.level = Logger::DEBUG
      conn.post '/ohyes', 'name=Ebi', accept: 'text/html'
      expect(string_io.string).to match(%(name=Ebi))
      expect(string_io.string).to match(%(pebbles))
    end

    it 'logs headers on the debug level' do
      logger.level = Logger::DEBUG
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).to match(%(Content-Type: "text/html))
    end

    it 'does not log request/response body on the info level' do
      logger.level = Logger::INFO
      conn.post '/ohyes', 'name=Ebi', accept: 'text/html'
      expect(string_io.string).not_to match(%(name=Ebi))
      expect(string_io.string).not_to match(%(pebbles))
    end

    it 'does not log headers on the info level' do
      logger.level = Logger::INFO
      conn.get '/hello', nil, accept: 'text/html'
      expect(string_io.string).not_to match(%(Content-Type: "text/html))
    end
  end
end
