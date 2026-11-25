require 'rails_helper'

# `SafeFetch.fetch` is a custom method that requires a block (it yields a Result);
# it is NOT `Hash#fetch`, so RuboCop's autocorrect to `fetch(url, nil)` would break the API.
# rubocop:disable Style/RedundantFetchBlock
RSpec.describe SafeFetch do
  let(:url) { 'http://example.com/image.png' }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
  end

  describe '.fetch' do
    context 'with a valid public URL serving an image' do
      before do
        stub_request(:get, url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )
      end

      it 'yields a Result with tempfile, filename, and content_type' do
        described_class.fetch(url) do |result|
          expect(result.tempfile).to be_a(Tempfile)
          expect(result.filename).to eq('image.png')
          expect(result.content_type).to eq('image/png')
          expect(result.tempfile.size).to be > 0
        end
      end

      it 'closes the tempfile after the block returns' do
        captured = nil
        described_class.fetch(url) { |result| captured = result.tempfile }
        expect(captured.closed?).to be true
      end

      it 'closes the tempfile even when the block raises' do
        captured = nil
        expect do
          described_class.fetch(url) do |result|
            captured = result.tempfile
            raise 'boom'
          end
        end.to raise_error('boom')
        expect(captured.closed?).to be true
      end

      it 'defaults the filename to a unique "download-<timestamp>-<hex>" when the URL has no path' do
        bare_url = 'http://example.com'
        stub_request(:get, bare_url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

        described_class.fetch(bare_url) do |result|
          expect(result.filename).to match(/\Adownload-\d+-[a-f0-9]{8}\z/)
        end
      end

      it 'requires a block' do
        expect { described_class.fetch(url) }.to raise_error(ArgumentError, /block required/)
      end
    end

    context 'with embedded basic auth credentials' do
      it 'passes decoded credentials to the request' do
        authenticated_url = 'http://user+avatar%40example.com:p%40ss+word%3A1@example.com/image.png'
        stub_request(:get, url)
          .with(headers: { 'Authorization' => 'Basic dXNlcithdmF0YXJAZXhhbXBsZS5jb206cEBzcyt3b3JkOjE=' })
          .to_return(
            status: 200,
            body: File.new(Rails.root.join('spec/assets/avatar.png')),
            headers: { 'Content-Type' => 'image/png' }
          )

        described_class.fetch(authenticated_url) do |result|
          expect(result.content_type).to eq('image/png')
        end
      end

      it 'preserves embedded credentials after a same-origin redirect removes userinfo' do
        authenticated_url = 'http://user:pass@example.com/protected.png'
        initial_url = 'http://example.com/protected.png'
        redirect_url = 'http://example.com/public.png'
        redirected_headers = nil

        stub_request(:get, initial_url)
          .with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNz' })
          .to_return(
            status: 302,
            headers: { 'Location' => '/public.png' }
          )
        stub_request(:get, redirect_url)
          .with do |request|
            redirected_headers = request.headers.transform_keys(&:downcase)
            true
          end
          .to_return(
            status: 200,
            body: File.new(Rails.root.join('spec/assets/avatar.png')),
            headers: { 'Content-Type' => 'image/png' }
          )

        described_class.fetch(authenticated_url) do |result|
          expect(result.content_type).to eq('image/png')
        end

        expect(redirected_headers).to include('authorization' => 'Basic dXNlcjpwYXNz')
      end

      it 'strips embedded credentials on cross-origin redirects' do
        authenticated_url = 'http://user:pass@example.com/protected.png'
        initial_url = 'http://example.com/protected.png'
        redirect_url = 'https://example.com/public.png'
        redirected_headers = nil

        stub_request(:get, initial_url)
          .with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNz' })
          .to_return(
            status: 302,
            headers: { 'Location' => redirect_url }
          )
        stub_request(:get, redirect_url)
          .with do |request|
            redirected_headers = request.headers.transform_keys(&:downcase)
            true
          end
          .to_return(
            status: 200,
            body: File.new(Rails.root.join('spec/assets/avatar.png')),
            headers: { 'Content-Type' => 'image/png' }
          )

        described_class.fetch(authenticated_url) do |result|
          expect(result.content_type).to eq('image/png')
        end

        expect(redirected_headers).not_to include('authorization')
      end
    end

    context 'with URL validation' do
      it 'raises InvalidUrlError for javascript: URLs' do
        expect { described_class.fetch('javascript:alert(1)') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end

      it 'raises InvalidUrlError for mailto: URLs' do
        expect { described_class.fetch('mailto:test@example.com') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end

      it 'raises InvalidUrlError for data: URLs' do
        expect { described_class.fetch('data:text/html,<x>') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end

      it 'raises InvalidUrlError for ftp: URLs' do
        expect { described_class.fetch('ftp://example.com/file') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end

      it 'raises InvalidUrlError for malformed URLs' do
        expect { described_class.fetch('not_a_url') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end

      it 'raises InvalidUrlError when host is missing' do
        expect { described_class.fetch('http:///path') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::InvalidUrlError')
        end
      end
    end

    context 'with SSRF protection (integration with ssrf_filter)' do
      it 'raises UnsafeUrlError for private IP literals (10.x.x.x)' do
        expect { described_class.fetch('http://10.0.0.1/secret') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
        end
      end

      it 'raises UnsafeUrlError for loopback addresses' do
        expect { described_class.fetch('http://127.0.0.1/secret') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
        end
      end

      it 'raises UnsafeUrlError for AWS metadata IP (169.254.169.254)' do
        expect { described_class.fetch('http://169.254.169.254/latest/meta-data/') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
        end
      end

      it 'raises UnsafeUrlError when hostname resolves to a private IP (DNS rebinding)' do
        allow(Resolv).to receive(:getaddresses).with('evil.example.com').and_return(['10.0.0.1'])
        expect { described_class.fetch('http://evil.example.com/secret') { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
        end
      end

      it 'allows private IP literals when private network access is enabled' do
        private_url = 'http://192.168.3.21/image.png'
        allow(Resolv).to receive(:getaddresses).with('192.168.3.21').and_return(['192.168.3.21'])
        stub_request(:get, private_url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

        with_modified_env('SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'true') do
          expect { described_class.fetch(private_url) { nil } }.not_to raise_error
        end
      end

      it 'allows private hostnames when private network access is enabled' do
        private_url = 'http://internal-webhook-service/image.png'
        allow(Resolv).to receive(:getaddresses).with('internal-webhook-service').and_return(['10.0.0.5'])
        stub_request(:get, private_url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

        with_modified_env('SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'true') do
          expect { described_class.fetch(private_url) { nil } }.not_to raise_error
        end
      end

      it 'allows redirects to private hostnames when private network access is enabled' do
        redirect_url = 'http://example.com/redirect.png'
        private_url = 'http://private.example.com/image.png'
        allow(Resolv).to receive(:getaddresses).with('private.example.com').and_return(['10.0.0.5'])
        stub_request(:get, redirect_url).to_return(status: 302, headers: { 'Location' => private_url })
        stub_request(:get, private_url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

        with_modified_env('SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'true') do
          expect { described_class.fetch(redirect_url) { nil } }.not_to raise_error
        end
      end

      it 'strips caller-provided sensitive headers on private network cross-origin redirects' do
        redirect_url = 'http://example.com/redirect.png'
        private_url = 'http://private.example.com/image.png'
        redirected_headers = nil
        allow(Resolv).to receive(:getaddresses).with('private.example.com').and_return(['10.0.0.5'])
        stub_request(:get, redirect_url).to_return(status: 302, headers: { 'Location' => private_url })
        stub_request(:get, private_url)
          .with do |request|
            redirected_headers = request.headers.transform_keys(&:downcase)
            true
          end
          .to_return(
            status: 200,
            body: File.new(Rails.root.join('spec/assets/avatar.png')),
            headers: { 'Content-Type' => 'image/png' }
          )

        with_modified_env('SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'true') do
          described_class.fetch(
            redirect_url,
            headers: { 'X-API-Key' => 'secret-key' },
            sensitive_headers: ['X-API-Key']
          ) { nil }
        end

        expect(redirected_headers).not_to include('x-api-key')
      end
    end

    # fazer-ai/chatwoot#927
    context 'with SAFE_FETCH_PRIVATE_TARGETS' do
      let(:png) { { status: 200, body: File.new(Rails.root.join('spec/assets/avatar.png')), headers: { 'Content-Type' => 'image/png' } } }

      def fetch_with_targets(url, targets = '10.40.10.20:3000')
        with_modified_env('SAFE_FETCH_PRIVATE_TARGETS' => targets) { described_class.fetch(url) { nil } }
      end

      def expect_unsafe(&)
        expect(&).to(raise_error { |error| expect(error.class.name).to eq('SafeFetch::UnsafeUrlError') })
      end

      it 'allows a listed host:port over http' do
        stub = stub_request(:get, 'http://10.40.10.20:3000/hook').to_return(png)

        expect { fetch_with_targets('http://10.40.10.20:3000/hook') }.not_to raise_error
        expect(stub).to have_been_requested
      end

      it 'allows a listed host:port over https' do
        stub = stub_request(:get, 'https://10.40.10.20:3000/hook').to_return(png)

        expect { fetch_with_targets('https://10.40.10.20:3000/hook') }.not_to raise_error
        expect(stub).to have_been_requested
      end

      it 'allows a listed hostname that resolves to a private address' do
        allow(Resolv).to receive(:getaddresses).with('agents.internal').and_return(['10.40.10.20'])
        stub = stub_request(:get, 'http://agents.internal:3000/hook').to_return(png)

        expect { fetch_with_targets('http://agents.internal:3000/hook', 'Agents.Internal:3000') }.not_to raise_error
        expect(stub).to have_been_requested
      end

      it 'matches the host case-insensitively' do
        allow(Resolv).to receive(:getaddresses).with('AGENTS.internal').and_return(['10.40.10.20'])
        stub = stub_request(:get, 'http://agents.internal:3000/hook').to_return(png)

        expect { fetch_with_targets('http://AGENTS.internal:3000/hook', 'agents.internal:3000') }.not_to raise_error
        expect(stub).to have_been_requested
      end

      it 'refuses a redirect from a listed target to a URL without a host' do
        stub_request(:get, 'http://10.40.10.20:3000/hook').to_return(status: 302, headers: { 'Location' => 'http:/escape' })

        expect_unsafe { fetch_with_targets('http://10.40.10.20:3000/hook') }
      end

      it 'refuses another private host on the same port' do
        stub = stub_request(:get, 'http://10.40.10.21:3000/hook')

        expect_unsafe { fetch_with_targets('http://10.40.10.21:3000/hook') }
        expect(stub).not_to have_been_requested
      end

      it 'refuses the listed host on another port' do
        stub = stub_request(:get, 'http://10.40.10.20:5432/hook')

        expect_unsafe { fetch_with_targets('http://10.40.10.20:5432/hook') }
        expect(stub).not_to have_been_requested
      end

      it 'refuses the listed host on the default port' do
        stub = stub_request(:get, 'http://10.40.10.20/hook')

        expect_unsafe { fetch_with_targets('http://10.40.10.20/hook') }
        expect(stub).not_to have_been_requested
      end

      it 'refuses a redirect from a listed target to a host:port outside the list' do
        stub_request(:get, 'http://10.40.10.20:3000/hook').to_return(status: 302, headers: { 'Location' => 'http://10.40.10.20:5432/escape' })
        escape = stub_request(:get, 'http://10.40.10.20:5432/escape')

        expect_unsafe { fetch_with_targets('http://10.40.10.20:3000/hook') }
        expect(escape).not_to have_been_requested
      end

      it 'refuses a redirect from a listed target to a public host outside the list' do
        stub_request(:get, 'http://10.40.10.20:3000/hook').to_return(status: 302, headers: { 'Location' => 'http://example.com/escape' })
        escape = stub_request(:get, 'http://example.com/escape')

        expect_unsafe { fetch_with_targets('http://10.40.10.20:3000/hook') }
        expect(escape).not_to have_been_requested
      end

      it 'follows a redirect between listed targets' do
        stub_request(:get, 'http://10.40.10.20:3000/hook').to_return(status: 302, headers: { 'Location' => '/final' })
        stub_request(:get, 'http://10.40.10.20:3000/final').to_return(status: 302, headers: { 'Location' => 'http://10.40.10.20:3001/final' })
        final = stub_request(:get, 'http://10.40.10.20:3001/final').to_return(png)

        expect { fetch_with_targets('http://10.40.10.20:3000/hook', '10.40.10.20:3000, 10.40.10.20:3001') }.not_to raise_error
        expect(final).to have_been_requested
      end

      it 'keeps public URLs on the default guard' do
        stub = stub_request(:get, 'http://example.com/image.png').to_return(png)

        expect { fetch_with_targets('http://example.com/image.png') }.not_to raise_error
        expect(stub).to have_been_requested
      end

      it 'keeps refusing private addresses when the list is empty' do
        expect_unsafe { fetch_with_targets('http://10.40.10.20:3000/hook', '') }
      end

      it 'lets SAFE_FETCH_ALLOW_PRIVATE_NETWORK open every private address' do
        stub = stub_request(:get, 'http://10.40.10.21:5432/hook').to_return(png)

        with_modified_env('SAFE_FETCH_ALLOW_PRIVATE_NETWORK' => 'true') do
          expect { fetch_with_targets('http://10.40.10.21:5432/hook') }.not_to raise_error
        end
        expect(stub).to have_been_requested
      end
    end

    context 'with content-type allowlist' do
      it 'rejects text/html responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: '<html></html>',
          headers: { 'Content-Type' => 'text/html' }
        )

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsupportedContentTypeError')
        end
      end

      it 'rejects application/octet-stream responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x',
          headers: { 'Content-Type' => 'application/octet-stream' }
        )

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsupportedContentTypeError')
        end
      end

      it 'allows video/mp4 responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'video/mp4' }
        )

        expect { described_class.fetch(url) { nil } }.not_to raise_error
      end

      it 'normalizes parameters and casing before yielding content_type' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x',
          headers: { 'Content-Type' => 'IMAGE/PNG; charset=binary' }
        )

        described_class.fetch(url) do |result|
          expect(result.content_type).to eq('image/png')
        end
      end

      it 'allows exact content-type matches when prefixes are empty' do
        pdf_url = 'http://example.com/file.pdf'
        stub_request(:get, pdf_url).to_return(
          status: 200,
          body: 'pdf-data',
          headers: { 'Content-Type' => 'application/pdf' }
        )

        expect do
          described_class.fetch(
            pdf_url,
            allowed_content_type_prefixes: [],
            allowed_content_types: ['application/pdf']
          ) { nil }
        end.not_to raise_error
      end

      it 'rejects exact content-type mismatches when prefixes are empty' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x',
          headers: { 'Content-Type' => 'image/webp' }
        )

        expect { described_class.fetch(url, allowed_content_type_prefixes: [], allowed_content_types: ['image/png']) { nil } }
          .to raise_error do |error|
            expect(error.class.name).to eq('SafeFetch::UnsupportedContentTypeError')
          end
      end

      it 'rejects when the content-type header is missing' do
        stub_request(:get, url).to_return(status: 200, body: 'x', headers: {})

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsupportedContentTypeError')
        end
      end
    end

    context 'with custom request options' do
      let(:post_body) { { hello: 'world' }.to_json }
      let(:headers) do
        {
          'Authorization' => 'Bearer test-token',
          'Content-Type' => 'application/json'
        }
      end

      it 'supports POST requests with custom headers when content-type validation is disabled' do
        stub_request(:post, url)
          .with(body: post_body, headers: headers)
          .to_return(status: 200, body: '', headers: {})

        expect do
          described_class.fetch(
            url,
            method: :post,
            body: post_body,
            headers: headers,
            validate_content_type: false
          ) { nil }
        end.not_to raise_error
      end

      it 'preserves non-credential headers on cross-origin redirects' do
        redirect_url = 'https://example.com/image.png'
        redirected_headers = nil
        headers = {
          'Authorization' => 'Bearer test-token',
          'Cookie' => 'session=test',
          'Content-Type' => 'application/json',
          'X-Chatwoot-Delivery' => 'test-uuid',
          'X-Chatwoot-Signature' => 'sha256=test-signature'
        }

        stub_request(:post, url).to_return(
          status: 307,
          headers: { 'Location' => redirect_url }
        )
        stub_request(:post, redirect_url)
          .with do |request|
            redirected_headers = request.headers.transform_keys(&:downcase)
            true
          end
          .to_return(status: 200, body: '', headers: {})

        described_class.fetch(
          url,
          method: :post,
          body: post_body,
          headers: headers,
          validate_content_type: false
        ) { nil }

        expect(redirected_headers).to include(
          'content-type' => 'application/json',
          'x-chatwoot-delivery' => 'test-uuid',
          'x-chatwoot-signature' => 'sha256=test-signature'
        )
        expect(redirected_headers).not_to include('authorization', 'cookie')
      end

      it 'strips caller-provided sensitive headers on cross-origin redirects' do
        redirect_url = 'https://example.com/image.png'
        redirected_headers = nil
        headers = { 'X-API-Key' => 'secret-key' }

        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => redirect_url })
        stub_request(:get, redirect_url)
          .with do |request|
            redirected_headers = request.headers.transform_keys(&:downcase)
            true
          end
          .to_return(status: 200, body: '', headers: {})

        described_class.fetch(
          url,
          headers: headers,
          sensitive_headers: ['X-API-Key'],
          validate_content_type: false
        ) { nil }

        expect(redirected_headers).not_to include('x-api-key')
      end

      it 'preserves caller-provided sensitive headers on same-origin redirects' do
        redirect_url = 'http://example.com/redirected.png'

        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/redirected.png' })
        stub_request(:get, redirect_url)
          .with(headers: { 'X-API-Key' => 'secret-key' })
          .to_return(status: 200, body: '', headers: {})

        described_class.fetch(
          url,
          headers: { 'X-API-Key' => 'secret-key' },
          sensitive_headers: ['X-API-Key'],
          validate_content_type: false
        ) { nil }

        expect(WebMock).to have_requested(:get, redirect_url).with(headers: { 'X-API-Key' => 'secret-key' })
      end

      it 'raises UnsupportedMethodError for unsupported HTTP methods' do
        expect { described_class.fetch(url, method: :options) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::UnsupportedMethodError')
        end
      end
    end

    context 'with body size cap' do
      it 'honours a custom max_bytes argument' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'xxxxx',
          headers: { 'Content-Type' => 'image/png' }
        )

        expect { described_class.fetch(url, max_bytes: 2) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::FileTooLargeError')
        end
      end

      it 'reads the default cap from GlobalConfigService MAXIMUM_FILE_UPLOAD_SIZE (matching Attachment#validate_file_size)' do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('MAXIMUM_FILE_UPLOAD_SIZE', 40).and_return('1')

        oversize = 'x' * (1.megabyte + 1)
        stub_request(:get, url).to_return(
          status: 200,
          body: oversize,
          headers: { 'Content-Type' => 'image/png' }
        )

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::FileTooLargeError')
        end
      end

      it 'falls back to 40 MB when GlobalConfigService returns a non-positive value' do
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('MAXIMUM_FILE_UPLOAD_SIZE', 40).and_return('-10')

        # 1 MB body should pass under the 40 MB fallback
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x' * 1.megabyte,
          headers: { 'Content-Type' => 'image/png' }
        )

        expect { described_class.fetch(url) { nil } }.not_to raise_error
      end

      it 'allows uploads between the old hardcoded 10 MB and the configured limit (regression check)' do
        # Default config is 40 MB; a 15 MB upload must succeed.
        # This is the exact regression scenario: with the old hardcoded 10 MB cap,
        # this would have failed even though direct file uploads of the same size succeed.
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('MAXIMUM_FILE_UPLOAD_SIZE', 40).and_return('40')

        stub_request(:get, url).to_return(
          status: 200,
          body: 'x' * (15 * 1024 * 1024),
          headers: { 'Content-Type' => 'image/png' }
        )

        expect { described_class.fetch(url) { nil } }.not_to raise_error
      end
    end

    context 'with network failures' do
      it 'maps Net::ReadTimeout to FetchError' do
        stub_request(:get, url).to_raise(Net::ReadTimeout)

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::FetchError')
        end
      end

      it 'maps SocketError to FetchError' do
        stub_request(:get, url).to_raise(SocketError.new('connection refused'))

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::FetchError')
        end
      end
    end

    context 'with non-2xx upstream responses' do
      it 'raises HttpError on non-2xx responses' do
        stub_request(:get, url).to_return(status: 404, body: '', headers: {})

        expect { described_class.fetch(url) { nil } }.to raise_error do |error|
          expect(error.class.name).to eq('SafeFetch::HttpError')
        end
      end
    end
  end

  # fazer-ai/chatwoot#927
  describe '.private_targets' do
    it 'parses comma-separated host:port entries' do
      with_modified_env('SAFE_FETCH_PRIVATE_TARGETS' => ' 10.40.10.20:3000 ,Agents.Internal:8080,[fd00::1]:443') do
        expect(described_class.private_targets).to eq([['10.40.10.20', 3000], ['agents.internal', 8080], ['fd00::1', 443]])
      end
    end

    it 'is empty when the variable is unset' do
      with_modified_env('SAFE_FETCH_PRIVATE_TARGETS' => nil) do
        expect(described_class.private_targets).to eq([])
      end
    end

    ['10.40.10.20', '10.40.10.20:3000,10.40.10.21', '10.40.10.20:', 'http://10.40.10.20:3000'].each do |value|
      it "raises on an entry without a valid port (#{value})" do
        with_modified_env('SAFE_FETCH_PRIVATE_TARGETS' => value) do
          expect { described_class.private_targets }.to raise_error(ArgumentError, /SAFE_FETCH_PRIVATE_TARGETS/)
        end
      end
    end
  end
end
# rubocop:enable Style/RedundantFetchBlock
