require_relative '_lib'
require 'json'

require 'zlib'

describe RestClient::Request do
  before(:all) do
    WebMock.disable!
  end

  after(:all) do
    WebMock.enable!
  end

  def default_httpbin_url
    # add a hack to work around java/jruby bug
    # java.lang.RuntimeException: Could not generate DH keypair with backtrace
    # Also (2017-04-09) Travis Jruby versions have a broken CA keystore
    if ENV['TRAVIS_RUBY_VERSION'] =~ /\Ajruby-/
      'http://httpbin.org/'
    else
      'https://httpbin.org/'
    end
  end

  def httpbin(suffix='')
    url = ENV.fetch('HTTPBIN_URL', default_httpbin_url)
    unless url.end_with?('/')
      url += '/'
    end

    url + suffix
  end

  def execute_httpbin(suffix, opts={})
    opts = {url: httpbin(suffix)}.merge(opts)
    RestClient::Request.execute(opts)
  end

  def execute_httpbin_json(suffix, opts={})
    JSON.parse(execute_httpbin(suffix, opts))
  end

  describe '.execute' do
    it 'sends a user agent' do
      data = execute_httpbin_json('user-agent', method: :get)
      expect(data['user-agent']).to match(/rest-client/)
    end

    it 'receives cookies on 302' do
      expect {
        execute_httpbin('cookies/set?foo=bar', method: :get, max_redirects: 0)
      }.to raise_error(RestClient::Found) { |ex|
        expect(ex.http_code).to eq 302
        expect(ex.response.cookies['foo']).to eq 'bar'
      }
    end

    it 'passes along cookies through 302' do
      data = execute_httpbin_json('cookies/set?foo=bar', method: :get)
      expect(data).to have_key('cookies')
      expect(data['cookies']['foo']).to eq 'bar'
    end

    it 'handles quote wrapped cookies' do
      expect {
        execute_httpbin('cookies/set?foo=' + CGI.escape('"bar:baz"'),
                        method: :get, max_redirects: 0)
      }.to raise_error(RestClient::Found) { |ex|
        expect(ex.http_code).to eq 302
        expect(ex.response.cookies['foo']).to eq '"bar:baz"'
      }
    end

    it 'sends basic auth' do
      user = 'user'
      pass = 'pass'

      data = execute_httpbin_json("basic-auth/#{user}/#{pass}", method: :get, user: user, password: pass)
      expect(data).to eq({'authenticated' => true, 'user' => user})

      expect {
        execute_httpbin_json("basic-auth/#{user}/#{pass}", method: :get, user: user, password: 'badpass')
      }.to raise_error(RestClient::Unauthorized) { |ex|
        expect(ex.http_code).to eq 401
      }
    end

    it 'handles gzipped/deflated responses' do
      [['gzip', 'gzipped'], ['deflate', 'deflated']].each do |encoding, var|
        raw = execute_httpbin(encoding, method: :get)

        begin
          data = JSON.parse(raw)
        rescue StandardError
          puts "Failed to parse: " + raw.inspect
          raise
        end

        expect(data['method']).to eq 'GET'
        expect(data.fetch(var)).to be true
      end
    end

    it 'does not uncompress response when accept-encoding is set' do
      # == gzip ==
      raw = execute_httpbin('gzip', method: :get, headers: {accept_encoding: 'gzip, deflate'})

      # check for gzip magic number
      expect(raw.body).to start_with("\x1F\x8B".b)

      decoded = Zlib::GzipReader.new(StringIO.new(raw.body)).read
      parsed = JSON.parse(decoded)

      expect(parsed['method']).to eq 'GET'
      expect(parsed.fetch('gzipped')).to be true

      # == delate ==
      raw = execute_httpbin('deflate', method: :get, headers: {accept_encoding: 'gzip, deflate'})

      decoded = Zlib::Inflate.new.inflate(raw.body)
      parsed = JSON.parse(decoded)

      expect(parsed['method']).to eq 'GET'
      expect(parsed.fetch('deflated')).to be true
    end
  end
end
