# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UrlSsrfValidator do
  describe '.validate!' do
    context 'with public URLs' do
      it 'allows https URLs' do
        allow(Resolv).to receive(:getaddresses).with('api.stripe.com').and_return(['104.16.111.56'])
        expect { described_class.validate!('https://api.stripe.com/v1/charges') }.not_to raise_error
      end

      it 'allows http URLs' do
        allow(Resolv).to receive(:getaddresses).with('webhook.example.com').and_return(['93.184.216.34'])
        expect { described_class.validate!('http://webhook.example.com/callback') }.not_to raise_error
      end
    end

    context 'with blocked schemes' do
      it 'rejects file:// URLs' do
        expect { described_class.validate!('file:///etc/passwd') }.to raise_error(UrlSsrfValidator::SsrfError, /Blocked URL scheme/)
      end

      it 'rejects ftp:// URLs' do
        expect { described_class.validate!('ftp://internal.corp/data') }.to raise_error(UrlSsrfValidator::SsrfError, /Blocked URL scheme/)
      end

      it 'rejects gopher:// URLs' do
        expect { described_class.validate!('gopher://internal/1') }.to raise_error(UrlSsrfValidator::SsrfError, /Blocked URL scheme/)
      end
    end

    context 'with private IP addresses' do
      it 'blocks 127.0.0.1 (loopback)' do
        expect { described_class.validate!('http://127.0.0.1/admin') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks 10.x.x.x (RFC 1918)' do
        expect { described_class.validate!('http://10.0.0.1/internal') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks 172.16.x.x (RFC 1918)' do
        expect { described_class.validate!('http://172.16.0.1/internal') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks 192.168.x.x (RFC 1918)' do
        expect { described_class.validate!('http://192.168.1.1/router') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks 169.254.169.254 (cloud metadata)' do
        expect { described_class.validate!('http://169.254.169.254/latest/meta-data/') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks 0.0.0.0' do
        expect { described_class.validate!('http://0.0.0.0/') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end

      it 'blocks IPv6 loopback ::1' do
        expect { described_class.validate!('http://[::1]/') }.to raise_error(UrlSsrfValidator::SsrfError, /blocked IP range/)
      end
    end

    context 'with DNS rebinding protection' do
      it 'blocks hostnames that resolve to private IPs' do
        allow(Resolv).to receive(:getaddresses).with('evil.com').and_return(['10.0.0.1'])
        expect { described_class.validate!('https://evil.com/steal') }.to raise_error(UrlSsrfValidator::SsrfError, /resolves to blocked IP/)
      end

      it 'blocks hostnames that resolve to loopback' do
        allow(Resolv).to receive(:getaddresses).with('rebind.attacker.com').and_return(['127.0.0.1'])
        expect { described_class.validate!('https://rebind.attacker.com/') }.to raise_error(UrlSsrfValidator::SsrfError, /resolves to blocked IP/)
      end

      it 'blocks hostnames that resolve to metadata IP' do
        allow(Resolv).to receive(:getaddresses).with('metadata.attacker.com').and_return(['169.254.169.254'])
        expect { described_class.validate!('http://metadata.attacker.com/latest') }.to raise_error(UrlSsrfValidator::SsrfError, /resolves to blocked IP/)
      end
    end

    context 'with unresolvable hostnames' do
      it 'blocks hostnames that cannot be resolved' do
        allow(Resolv).to receive(:getaddresses).with('nonexistent.invalid').and_return([])
        expect { described_class.validate!('https://nonexistent.invalid/api') }.to raise_error(UrlSsrfValidator::SsrfError, /Cannot resolve/)
      end
    end

    context 'with missing or empty host' do
      it 'rejects URLs without a host' do
        expect { described_class.validate!('http://') }.to raise_error(UrlSsrfValidator::SsrfError, /missing host/)
      end
    end
  end

  describe '.safe?' do
    it 'returns true for safe public URLs' do
      allow(Resolv).to receive(:getaddresses).with('api.stripe.com').and_return(['104.16.111.56'])
      expect(described_class.safe?('https://api.stripe.com/v1/charges')).to be true
    end

    it 'returns false for private IPs' do
      expect(described_class.safe?('http://127.0.0.1/')).to be false
    end

    it 'returns false for blocked schemes' do
      expect(described_class.safe?('file:///etc/passwd')).to be false
    end

    it 'returns false for invalid URLs' do
      expect(described_class.safe?('')).to be false
    end
  end
end
