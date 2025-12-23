# frozen_string_literal: true

class CustomEncoder
  def encode(params)
    params.map { |k, v| "#{k.upcase}-#{v.to_s.upcase}" }.join(',')
  end

  def decode(params)
    params.split(',').to_h { |pair| pair.split('-') }
  end
end

shared_examples 'initializer with url' do
  context 'with simple url' do
    let(:address) { 'http://httpbingo.org' }

    it { expect(subject.host).to eq('httpbingo.org') }
    it { expect(subject.port).to eq(80) }
    it { expect(subject.scheme).to eq('http') }
    it { expect(subject.path_prefix).to eq('/') }
    it { expect(subject.params).to eq({}) }
  end

  context 'with complex url' do
    let(:address) { 'http://httpbingo.org:815/fish?a=1' }

    it { expect(subject.port).to eq(815) }
    it { expect(subject.path_prefix).to eq('/fish') }
    it { expect(subject.params).to eq('a' => '1') }
  end

  context 'with IPv6 address' do
    let(:address) { 'http://[::1]:85/' }

    it { expect(subject.host).to eq('[::1]') }
    it { expect(subject.port).to eq(85) }
  end
end

shared_examples 'default connection options' do
  after { Faraday.default_connection_options = nil }

  it 'works with implicit url' do
    conn = Faraday.new 'http://httpbingo.org/foo'
    expect(conn.options.timeout).to eq(10)
  end

  it 'works with option url' do
    conn = Faraday.new url: 'http://httpbingo.org/foo'
    expect(conn.options.timeout).to eq(10)
  end

  it 'works with instance connection options' do
    conn = Faraday.new 'http://httpbingo.org/foo', request: { open_timeout: 1 }
    expect(conn.options.timeout).to eq(10)
    expect(conn.options.open_timeout).to eq(1)
  end

  it 'default connection options persist with an instance overriding' do
    conn = Faraday.new 'http://nigiri.com/bar'
    conn.options.timeout = 1
    expect(Faraday.default_connection_options.request.timeout).to eq(10)

    other = Faraday.new url: 'https://httpbingo.org/foo'
    other.options.timeout = 1

    expect(Faraday.default_connection_options.request.timeout).to eq(10)
  end

  it 'default connection uses default connection options' do
    expect(Faraday.default_connection.options.timeout).to eq(10)
  end
end

RSpec.describe Faraday::Connection do
  let(:conn) { Faraday::Connection.new(url, options) }
  let(:url) { nil }
  let(:options) { nil }

  describe '.new' do
    subject { conn }

    context 'with implicit url param' do
      # Faraday::Connection.new('http://httpbingo.org')
      let(:url) { address }

      it_behaves_like 'initializer with url'
    end

    context 'with explicit url param' do
      # Faraday::Connection.new(url: 'http://httpbingo.org')
      let(:url) { { url: address } }

      it_behaves_like 'initializer with url'
    end

    context 'with custom builder' do
      let(:custom_builder) { Faraday::RackBuilder.new }
      let(:options) { { builder: custom_builder } }

      it { expect(subject.builder).to eq(custom_builder) }
    end

    context 'with custom params' do
      let(:options) { { params: { a: 1 } } }

      it { expect(subject.params).to eq('a' => 1) }
    end

    context 'with custom params and params in url' do
      let(:url) { 'http://httpbingo.org/fish?a=1&b=2' }
      let(:options) { { params: { a: 3 } } }
      it { expect(subject.params).to eq('a' => 3, 'b' => '2') }
    end

    context 'with basic_auth in url' do
      let(:url) { 'http://Aladdin:open%20sesame@httpbingo.org/fish' }

      it { expect(subject.headers['Authorization']).to eq('Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==') }
    end

    context 'with custom headers' do
      let(:options) { { headers: { user_agent: 'Faraday' } } }

      it { expect(subject.headers['User-agent']).to eq('Faraday') }
    end

    context 'with ssl false' do
      let(:options) { { ssl: { verify: false } } }

      it { expect(subject.ssl.verify?).to be_falsey }
    end

    context 'with verify_hostname false' do
      let(:options) { { ssl: { verify_hostname: false } } }

      it { expect(subject.ssl.verify_hostname?).to be_falsey }
    end

    context 'with empty block' do
      let(:conn) { Faraday::Connection.new {} }

      it { expect(conn.builder.handlers.size).to eq(0) }
    end

    context 'with block' do
      let(:conn) do
        Faraday::Connection.new(params: { 'a' => '1' }) do |faraday|
          faraday.adapter :test
          faraday.url_prefix = 'http://httpbingo.org/omnom'
        end
      end

      it { expect(conn.builder.handlers.size).to eq(0) }
      it { expect(conn.path_prefix).to eq('/omnom') }
    end
  end

  describe '#close' do
    before { Faraday.default_adapter = :test }
    after { Faraday.default_adapter = nil }

    it 'can close underlying app' do
      expect(conn.app).to receive(:close)
      conn.close
    end
  end

  describe '#build_exclusive_url' do
    context 'with relative path' do
      subject { conn.build_exclusive_url('sake.html') }

      it 'uses connection host as default host' do
        conn.host = 'httpbingo.org'
        expect(subject.host).to eq('httpbingo.org')
        expect(subject.scheme).to eq('http')
      end

      it do
        conn.path_prefix = '/fish'
        expect(subject.path).to eq('/fish/sake.html')
      end

      it do
        conn.path_prefix = '/'
        expect(subject.path).to eq('/sake.html')
      end

      it do
        conn.path_prefix = 'fish'
        expect(subject.path).to eq('/fish/sake.html')
      end

      it do
        conn.path_prefix = '/fish/'
        expect(subject.path).to eq('/fish/sake.html')
      end
    end

    context 'with absolute path' do
      subject { conn.build_exclusive_url('/sake.html') }

      after { expect(subject.path).to eq('/sake.html') }

      it { conn.path_prefix = '/fish' }
      it { conn.path_prefix = '/' }
      it { conn.path_prefix = 'fish' }
      it { conn.path_prefix = '/fish/' }
    end

    context 'with complete url' do
      subject { conn.build_exclusive_url('http://httpbingo.org/sake.html?a=1') }

      it { expect(subject.scheme).to eq('http') }
      it { expect(subject.host).to eq('httpbingo.org') }
      it { expect(subject.port).to eq(80) }
      it { expect(subject.path).to eq('/sake.html') }
      it { expect(subject.query).to eq('a=1') }
    end

    it 'overrides connection port for absolute url' do
      conn.port = 23
      uri = conn.build_exclusive_url('http://httpbingo.org')
      expect(uri.port).to eq(80)
    end

    it 'does not add ending slash given nil url' do
      conn.url_prefix = 'http://httpbingo.org/nigiri'
      uri = conn.build_exclusive_url
      expect(uri.path).to eq('/nigiri')
    end

    it 'does not add ending slash given empty url' do
      conn.url_prefix = 'http://httpbingo.org/nigiri'
      uri = conn.build_exclusive_url('')
      expect(uri.path).to eq('/nigiri')
    end

    it 'does not use connection params' do
      conn.url_prefix = 'http://httpbingo.org/nigiri'
      conn.params = { a: 1 }
      expect(conn.build_exclusive_url.to_s).to eq('http://httpbingo.org/nigiri')
    end

    it 'allows to provide params argument' do
      conn.url_prefix = 'http://httpbingo.org/nigiri'
      conn.params = { a: 1 }
      params = Faraday::Utils::ParamsHash.new
      params[:a] = 2
      uri = conn.build_exclusive_url(nil, params)
      expect(uri.to_s).to eq('http://httpbingo.org/nigiri?a=2')
    end

    it 'handles uri instances' do
      uri = conn.build_exclusive_url(URI('/sake.html'))
      expect(uri.path).to eq('/sake.html')
    end

    it 'always returns new URI instance' do
      conn.url_prefix = 'http://httpbingo.org'
      uri1 = conn.build_exclusive_url(nil)
      uri2 = conn.build_exclusive_url(nil)
      expect(uri1).not_to equal(uri2)
    end

    context 'with url_prefixed connection' do
      let(:url) { 'http://httpbingo.org/get/' }

      it 'parses url and changes scheme' do
        conn.scheme = 'https'
        uri = conn.build_exclusive_url('sake.html')
        expect(uri.to_s).to eq('https://httpbingo.org/get/sake.html')
      end

      it 'joins url to base with ending slash' do
        uri = conn.build_exclusive_url('sake.html')
        expect(uri.to_s).to eq('http://httpbingo.org/get/sake.html')
      end

      it 'used default base with ending slash' do
        uri = conn.build_exclusive_url
        expect(uri.to_s).to eq('http://httpbingo.org/get/')
      end

      it 'overrides base' do
        uri = conn.build_exclusive_url('/sake/')
        expect(uri.to_s).to eq('http://httpbingo.org/sake/')
      end
    end

    context 'with colon in path' do
      let(:url) { 'http://service.com' }

      it 'joins url to base when used absolute path' do
        conn = Faraday.new(url: url)
        uri = conn.build_exclusive_url('/service:search?limit=400')
        expect(uri.to_s).to eq('http://service.com/service:search?limit=400')
      end

      it 'joins url to base when used relative path' do
        conn = Faraday.new(url: url)
        uri = conn.build_exclusive_url('service:search?limit=400')
        expect(uri.to_s).to eq('http://service.com/service:search?limit=400')
      end

      it 'joins url to base when used with path prefix' do
        conn = Faraday.new(url: url)
        conn.path_prefix = '/api'
        uri = conn.build_exclusive_url('service:search?limit=400')
        expect(uri.to_s).to eq('http://service.com/api/service:search?limit=400')
      end
    end

    context 'with a custom `default_uri_parser`' do
      let(:url) { 'http://httpbingo.org' }
      let(:parser) { Addressable::URI }

      around do |example|
        with_default_uri_parser(parser) do
          example.run
        end
      end

      it 'does not raise error' do
        expect { conn.build_exclusive_url('/nigiri') }.not_to raise_error
      end
    end
  end

  describe '#build_url' do
    let(:url) { 'http://httpbingo.org/nigiri' }

    it 'uses params' do
      conn.params = { a: 1, b: 1 }
      expect(conn.build_url.to_s).to eq('http://httpbingo.org/nigiri?a=1&b=1')
    end

    it 'merges params' do
      conn.params = { a: 1, b: 1 }
      url = conn.build_url(nil, b: 2, c: 3)
      expect(url.to_s).to eq('http://httpbingo.org/nigiri?a=1&b=2&c=3')
    end
  end

  describe '#build_request' do
    let(:url) { 'https://ahttpbingo.org/sake.html' }
    let(:request) { conn.build_request(:get) }

    before do
      conn.headers = { 'Authorization' => 'token abc123' }
      request.headers.delete('Authorization')
    end

    it { expect(conn.headers.keys).to eq(['Authorization']) }
    it { expect(conn.headers.include?('Authorization')).to be_truthy }
    it { expect(request.headers.keys).to be_empty }
    it { expect(request.headers.include?('Authorization')).to be_falsey }
  end

  describe '#to_env' do
    subject { conn.build_request(:get).to_env(conn).url }

    let(:url) { 'http://httpbingo.org/sake.html' }
    let(:options) { { params: @params } }

    it 'parses url params into query' do
      @params = { 'a[b]' => '1 + 2' }
      expect(subject.query).to eq('a%5Bb%5D=1+%2B+2')
    end

    it 'escapes per spec' do
      @params = { 'a' => '1+2 foo~bar.-baz' }
      expect(subject.query).to eq('a=1%2B2+foo~bar.-baz')
    end

    it 'bracketizes nested params in query' do
      @params = { 'a' => { 'b' => 'c' } }
      expect(subject.query).to eq('a%5Bb%5D=c')
    end

    it 'bracketizes repeated params in query' do
      @params = { 'a' => [1, 2] }
      expect(subject.query).to eq('a%5B%5D=1&a%5B%5D=2')
    end

    it 'without braketizing repeated params in query' do
      @params = { 'a' => [1, 2] }
      conn.options.params_encoder = Faraday::FlatParamsEncoder
      expect(subject.query).to eq('a=1&a=2')
    end
  end

  describe 'proxy support' do
    it 'accepts string' do
      with_env 'http_proxy' => 'http://env-proxy.com:80' do
        conn.proxy = 'http://proxy.com'
        expect(conn.proxy.host).to eq('proxy.com')
      end
    end

    it 'accepts uri' do
      with_env 'http_proxy' => 'http://env-proxy.com:80' do
        conn.proxy = URI.parse('http://proxy.com')
        expect(conn.proxy.host).to eq('proxy.com')
      end
    end

    it 'accepts hash with string uri' do
      with_env 'http_proxy' => 'http://env-proxy.com:80' do
        conn.proxy = { uri: 'http://proxy.com', user: 'rick' }
        expect(conn.proxy.host).to eq('proxy.com')
        expect(conn.proxy.user).to eq('rick')
      end
    end

    it 'accepts hash' do
      with_env 'http_proxy' => 'http://env-proxy.com:80' do
        conn.proxy = { uri: URI.parse('http://proxy.com'), user: 'rick' }
        expect(conn.proxy.host).to eq('proxy.com')
        expect(conn.proxy.user).to eq('rick')
      end
    end

    it 'accepts http env' do
      with_env 'http_proxy' => 'http://env-proxy.com:80' do
        expect(conn.proxy.host).to eq('env-proxy.com')
      end
    end

    it 'accepts http env with auth' do
      with_env 'http_proxy' => 'http://a%40b:my%20pass@proxy.com:80' do
        expect(conn.proxy.user).to eq('a@b')
        expect(conn.proxy.password).to eq('my pass')
      end
    end

    it 'accepts env without scheme' do
      with_env 'http_proxy' => 'localhost:8888' do
        uri = conn.proxy[:uri]
        expect(uri.host).to eq('localhost')
        expect(uri.port).to eq(8888)
      end
    end

    it 'fetches no proxy from nil env' do
      with_env 'http_proxy' => nil do
        expect(conn.proxy).to be_nil
      end
    end

    it 'fetches no proxy from blank env' do
      with_env 'http_proxy' => '' do
        expect(conn.proxy).to be_nil
      end
    end

    it 'does not accept uppercase env' do
      with_env 'HTTP_PROXY' => 'http://localhost:8888/' do
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows when url in no proxy list' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example.com' do
        conn = Faraday::Connection.new('http://example.com')
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows when url in no proxy list with url_prefix' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example.com' do
        conn = Faraday::Connection.new
        conn.url_prefix = 'http://example.com'
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows when prefixed url is not in no proxy list' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example.com' do
        conn = Faraday::Connection.new('http://prefixedexample.com')
        expect(conn.proxy.host).to eq('proxy.com')
      end
    end

    it 'allows when subdomain url is in no proxy list' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example.com' do
        conn = Faraday::Connection.new('http://subdomain.example.com')
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows when url not in no proxy list' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example2.com' do
        conn = Faraday::Connection.new('http://example.com')
        expect(conn.proxy.host).to eq('proxy.com')
      end
    end

    it 'allows when ip address is not in no proxy list but url is' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'localhost' do
        conn = Faraday::Connection.new('http://127.0.0.1')
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows when url is not in no proxy list but ip address is' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => '127.0.0.1' do
        conn = Faraday::Connection.new('http://localhost')
        expect(conn.proxy).to be_nil
      end
    end

    it 'allows in multi element no proxy list' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example0.com,example.com,example1.com' do
        expect(Faraday::Connection.new('http://example0.com').proxy).to be_nil
        expect(Faraday::Connection.new('http://example.com').proxy).to be_nil
        expect(Faraday::Connection.new('http://example1.com').proxy).to be_nil
        expect(Faraday::Connection.new('http://example2.com').proxy.host).to eq('proxy.com')
      end
    end

    it 'test proxy requires uri' do
      expect { conn.proxy = { uri: :bad_uri, user: 'rick' } }.to raise_error(ArgumentError)
    end

    it 'uses env http_proxy' do
      with_env 'http_proxy' => 'http://proxy.com' do
        conn = Faraday.new
        expect(conn.instance_variable_get(:@manual_proxy)).to be_falsey
        expect(conn.proxy_for_request('http://google.co.uk').host).to eq('proxy.com')
      end
    end

    it 'uses processes no_proxy before http_proxy' do
      with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'google.co.uk' do
        conn = Faraday.new
        expect(conn.instance_variable_get(:@manual_proxy)).to be_falsey
        expect(conn.proxy_for_request('http://google.co.uk')).to be_nil
      end
    end

    it 'uses env https_proxy' do
      with_env 'https_proxy' => 'https://proxy.com' do
        conn = Faraday.new
        expect(conn.instance_variable_get(:@manual_proxy)).to be_falsey
        expect(conn.proxy_for_request('https://google.co.uk').host).to eq('proxy.com')
      end
    end

    it 'uses processes no_proxy before https_proxy' do
      with_env 'https_proxy' => 'https://proxy.com', 'no_proxy' => 'google.co.uk' do
        conn = Faraday.new
        expect(conn.instance_variable_get(:@manual_proxy)).to be_falsey
        expect(conn.proxy_for_request('https://google.co.uk')).to be_nil
      end
    end

    it 'gives priority to manually set proxy' do
      with_env 'https_proxy' => 'https://proxy.com', 'no_proxy' => 'google.co.uk' do
        conn = Faraday.new
        conn.proxy = 'http://proxy2.com'

        expect(conn.instance_variable_get(:@manual_proxy)).to be_truthy
        expect(conn.proxy_for_request('https://google.co.uk').host).to eq('proxy2.com')
      end
    end

    it 'ignores env proxy if set that way' do
      with_env_proxy_disabled do
        with_env 'http_proxy' => 'http://duncan.proxy.com:80' do
          expect(conn.proxy).to be_nil
        end
      end
    end

    context 'performing a request' do
      let(:url) { 'http://example.com' }
      let(:conn) do
        Faraday.new do |f|
          f.adapter :test do |stubs|
            stubs.get(url) do
              [200, {}, 'ok']
            end
          end
        end
      end

      it 'dynamically checks proxy' do
        with_env 'http_proxy' => 'http://proxy.com:80' do
          expect(conn.proxy.uri.host).to eq('proxy.com')

          conn.get(url) do |req|
            expect(req.options.proxy.uri.host).to eq('proxy.com')
          end
        end

        conn.get(url)
        expect(conn.instance_variable_get(:@temp_proxy)).to be_nil
      end

      it 'dynamically check no proxy' do
        with_env 'http_proxy' => 'http://proxy.com', 'no_proxy' => 'example.com' do
          expect(conn.proxy.uri.host).to eq('proxy.com')

          conn.get('http://example.com') do |req|
            expect(req.options.proxy).to be_nil
          end
        end
      end
    end
  end

  describe '#dup' do
    subject { conn.dup }

    let(:url) { 'http://httpbingo.org/foo' }
    let(:options) do
      {
        ssl: { verify: :none },
        headers: { 'content-type' => 'text/plain' },
        params: { 'a' => '1' },
        request: { timeout: 5 }
      }
    end

    it { expect(subject.build_exclusive_url).to eq(conn.build_exclusive_url) }
    it { expect(subject.headers['content-type']).to eq('text/plain') }
    it { expect(subject.params['a']).to eq('1') }

    context 'after manual changes' do
      before do
        subject.headers['content-length'] = 12
        subject.params['b'] = '2'
        subject.options[:open_timeout] = 10
      end

      it { expect(subject.builder.handlers.size).to eq(1) }
      it { expect(conn.builder.handlers.size).to eq(1) }
      it { expect(conn.headers.key?('content-length')).to be_falsey }
      it { expect(conn.params.key?('b')).to be_falsey }
      it { expect(subject.options[:timeout]).to eq(5) }
      it { expect(conn.options[:open_timeout]).to be_nil }
    end
  end

  describe '#respond_to?' do
    it { expect(Faraday.respond_to?(:get)).to be_truthy }
    it { expect(Faraday.respond_to?(:post)).to be_truthy }
  end

  describe 'default_connection_options' do
    context 'assigning a default value' do
      before do
        Faraday.default_connection_options = nil
        Faraday.default_connection_options.request.timeout = 10
      end

      it_behaves_like 'default connection options'
    end

    context 'assigning a hash' do
      before { Faraday.default_connection_options = { request: { timeout: 10 } } }

      it_behaves_like 'default connection options'
    end

    context 'preserving a user_agent assigned via default_conncetion_options' do
      around do |example|
        old = Faraday.default_connection_options
        Faraday.default_connection_options = { headers: { user_agent: 'My Agent 1.2' } }
        example.run
        Faraday.default_connection_options = old
      end

      context 'when url is a Hash' do
        let(:conn) { Faraday.new(url: 'http://example.co', headers: { 'CustomHeader' => 'CustomValue' }) }

        it { expect(conn.headers).to eq('CustomHeader' => 'CustomValue', 'User-Agent' => 'My Agent 1.2') }
      end

      context 'when url is a String' do
        let(:conn) { Faraday.new('http://example.co', headers: { 'CustomHeader' => 'CustomValue' }) }

        it { expect(conn.headers).to eq('CustomHeader' => 'CustomValue', 'User-Agent' => 'My Agent 1.2') }
      end
    end
  end

  describe 'request params' do
    context 'with simple url' do
      let(:url) { 'http://example.com' }
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }

      before do
        conn.adapter(:test, stubs)
        stubs.get('http://example.com?a=a&p=3') do
          [200, {}, 'ok']
        end
      end

      after { stubs.verify_stubbed_calls }

      it 'test_overrides_request_params' do
        conn.get('?p=2&a=a', p: 3)
      end

      it 'test_overrides_request_params_block' do
        conn.get('?p=1&a=a', p: 2) do |req|
          req.params[:p] = 3
        end
      end

      it 'test_overrides_request_params_block_url' do
        conn.get(nil, p: 2) do |req|
          req.url('?p=1&a=a', 'p' => 3)
        end
      end
    end

    context 'with url and extra params' do
      let(:url) { 'http://example.com?a=1&b=2' }
      let(:options) { { params: { c: 3 } } }
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }

      before do
        conn.adapter(:test, stubs)
      end

      it 'merges connection and request params' do
        expected = 'http://example.com?a=1&b=2&c=3&limit=5&page=1'
        stubs.get(expected) { [200, {}, 'ok'] }
        conn.get('?page=1', limit: 5)
        stubs.verify_stubbed_calls
      end

      it 'allows to override all params' do
        expected = 'http://example.com?b=b'
        stubs.get(expected) { [200, {}, 'ok'] }
        conn.get('?p=1&a=a', p: 2) do |req|
          expect(req.params[:a]).to eq('a')
          expect(req.params['c']).to eq(3)
          expect(req.params['p']).to eq(2)
          req.params = { b: 'b' }
          expect(req.params['b']).to eq('b')
        end
        stubs.verify_stubbed_calls
      end

      it 'allows to set params_encoder for single request' do
        encoder = CustomEncoder.new
        expected = 'http://example.com/?A-1,B-2,C-3,FEELING-BLUE'
        stubs.get(expected) { [200, {}, 'ok'] }

        conn.get('/', a: 1, b: 2, c: 3, feeling: 'blue') do |req|
          req.options.params_encoder = encoder
        end
        stubs.verify_stubbed_calls
      end
    end

    context 'with default params encoder' do
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }

      before do
        conn.adapter(:test, stubs)
        stubs.get('http://example.com?color%5B%5D=blue&color%5B%5D=red') do
          [200, {}, 'ok']
        end
      end

      after { stubs.verify_stubbed_calls }

      it 'supports array params in url' do
        conn.get('http://example.com?color[]=blue&color[]=red')
      end

      it 'supports array params in params' do
        conn.get('http://example.com', color: %w[blue red])
      end
    end

    context 'with flat params encoder' do
      let(:options) { { request: { params_encoder: Faraday::FlatParamsEncoder } } }
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }

      before do
        conn.adapter(:test, stubs)
        stubs.get('http://example.com?color=blue&color=red') do
          [200, {}, 'ok']
        end
      end

      after { stubs.verify_stubbed_calls }

      it 'supports array params in params' do
        conn.get('http://example.com', color: %w[blue red])
      end

      context 'with array param in url' do
        let(:url) { 'http://example.com?color[]=blue&color[]=red' }

        it do
          conn.get('/')
        end
      end
    end
  end
end
