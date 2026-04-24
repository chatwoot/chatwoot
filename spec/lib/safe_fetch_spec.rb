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

    context 'with URL validation' do
      it 'raises InvalidUrlError for javascript: URLs' do
        expect { described_class.fetch('javascript:alert(1)') { nil } }
          .to raise_error(described_class::InvalidUrlError)
      end

      it 'raises InvalidUrlError for mailto: URLs' do
        expect { described_class.fetch('mailto:test@example.com') { nil } }
          .to raise_error(described_class::InvalidUrlError)
      end

      it 'raises InvalidUrlError for data: URLs' do
        expect { described_class.fetch('data:text/html,<x>') { nil } }
          .to raise_error(described_class::InvalidUrlError)
      end

      it 'raises InvalidUrlError for ftp: URLs' do
        expect { described_class.fetch('ftp://example.com/file') { nil } }
          .to raise_error(described_class::InvalidUrlError)
      end

      it 'raises InvalidUrlError for malformed URLs' do
        expect { described_class.fetch('not_a_url') { nil } }
          .to raise_error(described_class::InvalidUrlError)
      end

      it 'raises InvalidUrlError when host is missing' do
        expect { described_class.fetch('http:///path') { nil } }
          .to raise_error(described_class::InvalidUrlError, /missing host/)
      end
    end

    context 'with SSRF protection (integration with ssrf_filter)' do
      it 'raises UnsafeUrlError for private IP literals (10.x.x.x)' do
        expect { described_class.fetch('http://10.0.0.1/secret') { nil } }
          .to raise_error(described_class::UnsafeUrlError)
      end

      it 'raises UnsafeUrlError for loopback addresses' do
        expect { described_class.fetch('http://127.0.0.1/secret') { nil } }
          .to raise_error(described_class::UnsafeUrlError)
      end

      it 'raises UnsafeUrlError for AWS metadata IP (169.254.169.254)' do
        expect { described_class.fetch('http://169.254.169.254/latest/meta-data/') { nil } }
          .to raise_error(described_class::UnsafeUrlError)
      end

      it 'raises UnsafeUrlError when hostname resolves to a private IP (DNS rebinding)' do
        allow(Resolv).to receive(:getaddresses).with('evil.example.com').and_return(['10.0.0.1'])
        expect { described_class.fetch('http://evil.example.com/secret') { nil } }
          .to raise_error(described_class::UnsafeUrlError)
      end
    end

    context 'with content-type allowlist' do
      it 'rejects text/html responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: '<html></html>',
          headers: { 'Content-Type' => 'text/html' }
        )

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::UnsupportedContentTypeError)
      end

      it 'rejects application/octet-stream responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x',
          headers: { 'Content-Type' => 'application/octet-stream' }
        )

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::UnsupportedContentTypeError)
      end

      it 'allows video/mp4 responses' do
        stub_request(:get, url).to_return(
          status: 200,
          body: File.new(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'video/mp4' }
        )

        expect { described_class.fetch(url) { nil } }.not_to raise_error
      end

      it 'strips charset/boundary parameters before comparing' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'x',
          headers: { 'Content-Type' => 'image/png; charset=binary' }
        )

        expect { described_class.fetch(url) { nil } }.not_to raise_error
      end

      it 'rejects when the content-type header is missing' do
        stub_request(:get, url).to_return(status: 200, body: 'x', headers: {})

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::UnsupportedContentTypeError)
      end
    end

    context 'with body size cap' do
      it 'honours a custom max_bytes argument' do
        stub_request(:get, url).to_return(
          status: 200,
          body: 'xxxxx',
          headers: { 'Content-Type' => 'image/png' }
        )

        expect { described_class.fetch(url, max_bytes: 2) { nil } }
          .to raise_error(described_class::FileTooLargeError)
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

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::FileTooLargeError)
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

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::FetchError)
      end

      it 'maps SocketError to FetchError' do
        stub_request(:get, url).to_raise(SocketError.new('connection refused'))

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::FetchError)
      end
    end

    context 'with non-2xx upstream responses' do
      it 'raises HttpError with the status code in the message' do
        stub_request(:get, url).to_return(status: 404, body: '', headers: {})

        expect { described_class.fetch(url) { nil } }
          .to raise_error(described_class::HttpError, /404/)
      end
    end
  end
end
# rubocop:enable Style/RedundantFetchBlock
