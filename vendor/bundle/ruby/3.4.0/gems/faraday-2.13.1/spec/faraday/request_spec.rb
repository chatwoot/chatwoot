# frozen_string_literal: true

RSpec.describe Faraday::Request do
  let(:conn) do
    Faraday.new(url: 'http://httpbingo.org/api',
                headers: { 'Mime-Version' => '1.0' },
                request: { oauth: { consumer_key: 'anonymous' } })
  end
  let(:http_method) { :get }
  let(:block) { nil }

  subject { conn.build_request(http_method, &block) }

  context 'when nothing particular is configured' do
    it { expect(subject.http_method).to eq(:get) }
    it { expect(subject.to_env(conn).ssl.verify).to be_falsey }
    it { expect(subject.to_env(conn).ssl.verify_hostname).to be_falsey }
  end

  context 'when HTTP method is post' do
    let(:http_method) { :post }

    it { expect(subject.http_method).to eq(:post) }
  end

  context 'when setting the url on setup with a URI' do
    let(:block) { proc { |req| req.url URI.parse('foo.json?a=1') } }

    it { expect(subject.path).to eq(URI.parse('foo.json')) }
    it { expect(subject.params).to eq('a' => '1') }
    it { expect(subject.to_env(conn).url.to_s).to eq('http://httpbingo.org/api/foo.json?a=1') }
  end

  context 'when setting the url on setup with a string path and params' do
    let(:block) { proc { |req| req.url 'foo.json', 'a' => 1 } }

    it { expect(subject.path).to eq('foo.json') }
    it { expect(subject.params).to eq('a' => 1) }
    it { expect(subject.to_env(conn).url.to_s).to eq('http://httpbingo.org/api/foo.json?a=1') }
  end

  context 'when setting the url on setup with a path including params' do
    let(:block) { proc { |req| req.url 'foo.json?b=2&a=1#qqq' } }

    it { expect(subject.path).to eq('foo.json') }
    it { expect(subject.params).to eq('a' => '1', 'b' => '2') }
    it { expect(subject.to_env(conn).url.to_s).to eq('http://httpbingo.org/api/foo.json?a=1&b=2') }
  end

  context 'when setting a header on setup with []= syntax' do
    let(:block) { proc { |req| req['Server'] = 'Faraday' } }
    let(:headers) { subject.to_env(conn).request_headers }

    it { expect(subject.headers['Server']).to eq('Faraday') }
    it { expect(headers['mime-version']).to eq('1.0') }
    it { expect(headers['server']).to eq('Faraday') }
  end

  context 'when setting the body on setup' do
    let(:block) { proc { |req| req.body = 'hi' } }

    it { expect(subject.body).to eq('hi') }
    it { expect(subject.to_env(conn).body).to eq('hi') }
  end

  context 'with global request options set' do
    let(:env_request) { subject.to_env(conn).request }

    before do
      conn.options.timeout = 3
      conn.options.open_timeout = 5
      conn.ssl.verify = false
      conn.proxy = 'http://proxy.com'
    end

    it { expect(subject.options.timeout).to eq(3) }
    it { expect(subject.options.open_timeout).to eq(5) }
    it { expect(env_request.timeout).to eq(3) }
    it { expect(env_request.open_timeout).to eq(5) }

    context 'and per-request options set' do
      let(:block) do
        proc do |req|
          req.options.timeout = 10
          req.options.boundary = 'boo'
          req.options.oauth[:consumer_secret] = 'xyz'
          req.options.context = {
            foo: 'foo',
            bar: 'bar'
          }
        end
      end

      it { expect(subject.options.timeout).to eq(10) }
      it { expect(subject.options.open_timeout).to eq(5) }
      it { expect(env_request.timeout).to eq(10) }
      it { expect(env_request.open_timeout).to eq(5) }
      it { expect(env_request.boundary).to eq('boo') }
      it { expect(env_request.context).to eq(foo: 'foo', bar: 'bar') }
      it do
        oauth_expected = { consumer_secret: 'xyz', consumer_key: 'anonymous' }
        expect(env_request.oauth).to eq(oauth_expected)
      end
    end
  end

  it 'supports marshal serialization' do
    expect(Marshal.load(Marshal.dump(subject))).to eq(subject)
  end
end
