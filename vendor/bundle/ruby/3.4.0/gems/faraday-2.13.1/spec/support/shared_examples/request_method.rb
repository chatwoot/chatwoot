# frozen_string_literal: true

shared_examples 'proxy examples' do
  it 'handles requests with proxy' do
    res = conn.public_send(http_method, '/')

    expect(res.status).to eq(200)
  end

  it 'handles proxy failures' do
    request_stub.to_return(status: 407)

    expect { conn.public_send(http_method, '/') }.to raise_error(Faraday::ProxyAuthError)
  end
end

shared_examples 'a request method' do |http_method|
  let(:query_or_body) { method_with_body?(http_method) ? :body : :query }
  let(:response) { conn.public_send(http_method, '/') }

  unless http_method == :head && feature?(:skip_response_body_on_head)
    it 'retrieves the response body' do
      res_body = 'test'
      request_stub.to_return(body: res_body)
      expect(conn.public_send(http_method, '/').body).to eq(res_body)
    end
  end

  it 'handles headers with multiple values' do
    request_stub.to_return(headers: { 'Set-Cookie' => 'name=value' })
    expect(response.headers['set-cookie']).to eq('name=value')
  end

  it 'retrieves the response headers' do
    request_stub.to_return(headers: { 'Content-Type' => 'text/plain' })
    expect(response.headers['Content-Type']).to match(%r{text/plain})
    expect(response.headers['content-type']).to match(%r{text/plain})
  end

  it 'sends user agent' do
    request_stub.with(headers: { 'User-Agent' => 'Agent Faraday' })
    conn.public_send(http_method, '/', nil, user_agent: 'Agent Faraday')
  end

  it 'represents empty body response as blank string' do
    expect(response.body).to eq('')
  end

  it 'handles connection error' do
    request_stub.disable
    expect { conn.public_send(http_method, 'http://localhost:4') }.to raise_error(Faraday::ConnectionFailed)
  end

  on_feature :local_socket_binding do
    it 'binds local socket' do
      stub_request(http_method, 'http://example.com')

      host = '1.2.3.4'
      port = 1234
      conn_options[:request] = { bind: { host: host, port: port } }

      conn.public_send(http_method, '/')

      expect(conn.options[:bind][:host]).to eq(host)
      expect(conn.options[:bind][:port]).to eq(port)
    end
  end

  # context 'when wrong ssl certificate is provided' do
  #   let(:ca_file_path) { 'tmp/faraday-different-ca-cert.crt' }
  #   before { conn_options.merge!(ssl: { ca_file: ca_file_path }) }
  #
  #   it do
  #     expect { conn.public_send(http_method, '/') }.to raise_error(Faraday::SSLError) # do |ex|
  #       expect(ex.message).to include?('certificate')
  #     end
  #   end
  # end

  on_feature :request_body_on_query_methods do
    it 'sends request body' do
      request_stub.with({ body: 'test' })
      res = if query_or_body == :body
              conn.public_send(http_method, '/', 'test')
            else
              conn.public_send(http_method, '/') do |req|
                req.body = 'test'
              end
            end
      expect(res.env.request_body).to eq('test')
    end
  end

  it 'sends url encoded parameters' do
    payload = { name: 'zack' }
    request_stub.with({ query_or_body => payload })
    res = conn.public_send(http_method, '/', payload)
    if query_or_body == :query
      expect(res.env.request_body).to be_nil
    else
      expect(res.env.request_body).to eq('name=zack')
    end
  end

  it 'sends url encoded nested parameters' do
    payload = { name: { first: 'zack' } }
    request_stub.with({ query_or_body => payload })
    conn.public_send(http_method, '/', payload)
  end

  # TODO: This needs reimplementation: see https://github.com/lostisland/faraday/issues/718
  # Should raise Faraday::TimeoutError
  it 'supports timeout option' do
    conn_options[:request] = { timeout: 1 }
    request_stub.to_timeout
    exc = adapter == 'NetHttp' ? Faraday::ConnectionFailed : Faraday::TimeoutError
    expect { conn.public_send(http_method, '/') }.to raise_error(exc)
  end

  # TODO: This needs reimplementation: see https://github.com/lostisland/faraday/issues/718
  # Should raise Faraday::ConnectionFailed
  it 'supports open_timeout option' do
    conn_options[:request] = { open_timeout: 1 }
    request_stub.to_timeout
    exc = adapter == 'NetHttp' ? Faraday::ConnectionFailed : Faraday::TimeoutError
    expect { conn.public_send(http_method, '/') }.to raise_error(exc)
  end

  on_feature :reason_phrase_parse do
    it 'parses the reason phrase' do
      request_stub.to_return(status: [200, 'OK'])
      expect(response.reason_phrase).to eq('OK')
    end
  end

  on_feature :compression do
    # Accept-Encoding header not sent for HEAD requests as body is not expected in the response.
    unless http_method == :head
      it 'handles gzip compression' do
        request_stub.with(headers: { 'Accept-Encoding' => /\bgzip\b/ })
        conn.public_send(http_method, '/')
      end

      it 'handles deflate compression' do
        request_stub.with(headers: { 'Accept-Encoding' => /\bdeflate\b/ })
        conn.public_send(http_method, '/')
      end
    end
  end

  on_feature :streaming do
    describe 'streaming' do
      let(:streamed) { [] }

      context 'when response is empty' do
        it 'handles streaming' do
          env = nil
          conn.public_send(http_method, '/') do |req|
            req.options.on_data = proc do |chunk, size, block_env|
              streamed << [chunk, size]
              env ||= block_env
            end
          end

          expect(streamed).to eq([['', 0]])
          # TODO: enable this after updating all existing adapters to the new streaming API
          # expect(env).to be_a(Faraday::Env)
          # expect(env.status).to eq(200)
        end
      end

      context 'when response contains big data' do
        before { request_stub.to_return(body: big_string) }

        it 'handles streaming' do
          env = nil
          response = conn.public_send(http_method, '/') do |req|
            req.options.on_data = proc do |chunk, size, block_env|
              streamed << [chunk, size]
              env ||= block_env
            end
          end

          expect(response.body).to eq('')
          check_streaming_response(streamed, chunk_size: 16 * 1024)
          # TODO: enable this after updating all existing adapters to the new streaming API
          # expect(env).to be_a(Faraday::Env)
          # expect(env.status).to eq(200)
        end
      end
    end
  end

  on_feature :parallel do
    context 'with parallel setup' do
      before do
        @resp1 = nil
        @resp2 = nil
        @payload1 = { a: '1' }
        @payload2 = { b: '2' }

        request_stub
          .with({ query_or_body => @payload1 })
          .to_return(body: @payload1.to_json)

        stub_request(http_method, remote)
          .with({ query_or_body => @payload2 })
          .to_return(body: @payload2.to_json)

        conn.in_parallel do
          @resp1 = conn.public_send(http_method, '/', @payload1)
          @resp2 = conn.public_send(http_method, '/', @payload2)

          expect(conn.in_parallel?).to be_truthy
          expect(@resp1.body).to be_nil
          expect(@resp2.body).to be_nil
        end

        expect(conn.in_parallel?).to be_falsey
      end

      it 'handles parallel requests status' do
        expect(@resp1&.status).to eq(200)
        expect(@resp2&.status).to eq(200)
      end

      unless http_method == :head && feature?(:skip_response_body_on_head)
        it 'handles parallel requests body' do
          expect(@resp1&.body).to eq(@payload1.to_json)
          expect(@resp2&.body).to eq(@payload2.to_json)
        end
      end
    end
  end

  context 'when a proxy is provided as option' do
    before do
      conn_options[:proxy] = 'http://env-proxy.com:80'
    end

    include_examples 'proxy examples'
  end

  context 'when http_proxy env variable is set' do
    let(:proxy_url) { 'http://env-proxy.com:80' }

    around do |example|
      with_env 'http_proxy' => proxy_url do
        example.run
      end
    end

    include_examples 'proxy examples'

    context 'when the env proxy is ignored' do
      around do |example|
        with_env_proxy_disabled(&example)
      end

      include_examples 'proxy examples'
    end
  end
end
