# frozen_string_literal: true

RSpec.describe Faraday::Utils do
  describe 'headers parsing' do
    let(:multi_response_headers) do
      "HTTP/1.x 500 OK\r\nContent-Type: text/html; charset=UTF-8\r\n" \
        "HTTP/1.x 200 OK\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
    end

    it 'parse headers for aggregated responses' do
      headers = Faraday::Utils::Headers.new
      headers.parse(multi_response_headers)

      result = headers.to_hash

      expect(result['Content-Type']).to eq('application/json; charset=UTF-8')
    end
  end

  describe 'URI parsing' do
    let(:url) { 'http://example.com/abc' }

    it 'escapes safe buffer' do
      str = FakeSafeBuffer.new('$32,000.00')
      expect(Faraday::Utils.escape(str)).to eq('%2432%2C000.00')
    end

    it 'parses with default parser' do
      with_default_uri_parser(nil) do
        uri = normalize(url)
        expect(uri.host).to eq('example.com')
      end
    end

    it 'parses with URI' do
      with_default_uri_parser(::URI) do
        uri = normalize(url)
        expect(uri.host).to eq('example.com')
      end
    end

    it 'parses with block' do
      with_default_uri_parser(->(u) { "booya#{'!' * u.size}" }) do
        expect(normalize(url)).to eq('booya!!!!!!!!!!!!!!!!!!!!!!')
      end
    end

    it 'replaces headers hash' do
      headers = Faraday::Utils::Headers.new('authorization' => 't0ps3cr3t!')
      expect(headers).to have_key('authorization')

      headers.replace('content-type' => 'text/plain')
      expect(headers).not_to have_key('authorization')
    end
  end

  describe '.deep_merge!' do
    let(:connection_options) { Faraday::ConnectionOptions.new }
    let(:url) do
      {
        url: 'http://example.com/abc',
        headers: { 'Mime-Version' => '1.0' },
        request: { oauth: { consumer_key: 'anonymous' } },
        ssl: { version: '2' }
      }
    end

    it 'recursively merges the headers' do
      connection_options.headers = { user_agent: 'My Agent 1.0' }
      deep_merge = Faraday::Utils.deep_merge!(connection_options, url)

      expect(deep_merge.headers).to eq('Mime-Version' => '1.0', user_agent: 'My Agent 1.0')
    end

    context 'when a target hash has an Options Struct value' do
      let(:request) do
        {
          params_encoder: nil,
          proxy: nil,
          bind: nil,
          timeout: nil,
          open_timeout: nil,
          read_timeout: nil,
          write_timeout: nil,
          boundary: nil,
          oauth: { consumer_key: 'anonymous' },
          context: nil,
          on_data: nil
        }
      end
      let(:ssl) do
        {
          verify: nil,
          ca_file: nil,
          ca_path: nil,
          verify_mode: nil,
          cert_store: nil,
          client_cert: nil,
          client_key: nil,
          certificate: nil,
          private_key: nil,
          verify_depth: nil,
          version: '2',
          min_version: nil,
          max_version: nil,
          verify_hostname: nil,
          hostname: nil,
          ciphers: nil
        }
      end

      it 'does not overwrite an Options Struct value' do
        deep_merge = Faraday::Utils.deep_merge!(connection_options, url)

        expect(deep_merge.request.to_h).to eq(request)
        expect(deep_merge.ssl.to_h).to eq(ssl)
      end
    end
  end
end
