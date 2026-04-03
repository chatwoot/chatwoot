require 'rails_helper'

RSpec.describe UrlSafetyValidator do
  describe '.safe?' do
    context 'with safe URLs' do
      it 'returns true for valid public URLs' do
        expect(described_class.safe?('https://example.com/image.png')).to be true
        expect(described_class.safe?('http://example.org/file.pdf')).to be true
      end
    end

    context 'with unsafe URLs' do
      it 'returns false for private IP ranges' do
        expect(described_class.safe?('http://10.0.0.1/secret')).to be false
        expect(described_class.safe?('http://172.16.0.1/secret')).to be false
        expect(described_class.safe?('http://192.168.1.1/secret')).to be false
      end

      it 'returns false for loopback addresses' do
        expect(described_class.safe?('http://127.0.0.1/secret')).to be false
        expect(described_class.safe?('http://127.0.0.254/secret')).to be false
      end

      it 'returns false for AWS metadata service' do
        expect(described_class.safe?('http://169.254.169.254/latest/meta-data/')).to be false
      end

      it 'returns false for localhost' do
        expect(described_class.safe?('http://localhost/secret')).to be false
      end

      it 'returns false for invalid schemes' do
        expect(described_class.safe?('ftp://example.com/file')).to be false
        expect(described_class.safe?('file:///etc/passwd')).to be false
      end
    end
  end

  describe '.validate!' do
    context 'with safe URLs' do
      before do
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
      end

      it 'returns true for valid public URLs' do
        expect(described_class.validate!('https://example.com/image.png')).to be true
      end
    end

    context 'with private IP ranges' do
      it 'raises UnsafeUrlError for Class A private IPs' do
        expect { described_class.validate!('http://10.0.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for Class B private IPs' do
        expect { described_class.validate!('http://172.16.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
        expect { described_class.validate!('http://172.31.255.255/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for Class C private IPs' do
        expect { described_class.validate!('http://192.168.1.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end
    end

    context 'with loopback addresses' do
      it 'raises UnsafeUrlError for localhost IP' do
        expect { described_class.validate!('http://127.0.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for any loopback IP' do
        expect { described_class.validate!('http://127.0.0.254/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end
    end

    context 'with AWS/cloud metadata service' do
      it 'raises UnsafeUrlError for link-local IPs (169.254.x.x)' do
        expect { described_class.validate!('http://169.254.169.254/latest/meta-data/') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for AWS metadata IP as hostname' do
        expect { described_class.validate!('http://169.254.169.254/latest/meta-data/iam/security-credentials/') }
          .to raise_error(described_class::UnsafeUrlError)
      end

      it 'raises UnsafeUrlError for GCP metadata hostname' do
        expect { described_class.validate!('http://metadata.google.internal/computeMetadata/v1/') }
          .to raise_error(described_class::UnsafeUrlError, /Blocked hostname/)
      end
    end

    context 'with blocked hostnames' do
      it 'raises UnsafeUrlError for localhost' do
        expect { described_class.validate!('http://localhost/secret') }
          .to raise_error(described_class::UnsafeUrlError, /Blocked hostname/)
      end

      it 'raises UnsafeUrlError for .local domains' do
        allow(Resolv).to receive(:getaddresses).with('server.local').and_return(['192.168.1.100'])
        expect { described_class.validate!('http://server.local/secret') }
          .to raise_error(described_class::UnsafeUrlError, /\.local is not allowed/)
      end

      it 'raises UnsafeUrlError for .internal domains' do
        allow(Resolv).to receive(:getaddresses).with('server.internal').and_return(['10.0.0.1'])
        expect { described_class.validate!('http://server.internal/secret') }
          .to raise_error(described_class::UnsafeUrlError, /\.internal is not allowed/)
      end

      it 'raises UnsafeUrlError for kubernetes.default.svc' do
        expect { described_class.validate!('http://kubernetes.default.svc/api') }
          .to raise_error(described_class::UnsafeUrlError, /Blocked hostname/)
      end
    end

    context 'with DNS rebinding protection' do
      it 'raises UnsafeUrlError when hostname resolves to private IP' do
        allow(Resolv).to receive(:getaddresses).with('evil.com').and_return(['10.0.0.1'])
        expect { described_class.validate!('http://evil.com/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError when any resolved IP is blocked' do
        allow(Resolv).to receive(:getaddresses).with('multi.com').and_return(['93.184.216.34', '127.0.0.1'])
        expect { described_class.validate!('http://multi.com/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end
    end

    context 'with invalid URLs' do
      it 'raises UnsafeUrlError for non-HTTP schemes' do
        expect { described_class.validate!('ftp://example.com/file') }
          .to raise_error(described_class::UnsafeUrlError, /HTTP or HTTPS/)
      end

      it 'raises URI::InvalidURIError for malformed URLs' do
        expect { described_class.validate!('not_a_url') }
          .to raise_error(URI::InvalidURIError)
      end

      it 'raises UnsafeUrlError for URLs without host' do
        expect { described_class.validate!('http:///path') }
          .to raise_error(described_class::UnsafeUrlError, /valid host/)
      end
    end

    context 'with IPv6 addresses' do
      it 'raises UnsafeUrlError for IPv6 loopback' do
        expect { described_class.validate!('http://[::1]/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for IPv6 unique local addresses' do
        expect { described_class.validate!('http://[fc00::1]/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for IPv6 link-local addresses' do
        expect { described_class.validate!('http://[fe80::1]/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end
    end

    context 'with special IP ranges' do
      it 'raises UnsafeUrlError for current network (0.0.0.0/8)' do
        expect { described_class.validate!('http://0.0.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for carrier-grade NAT' do
        expect { described_class.validate!('http://100.64.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for multicast addresses' do
        expect { described_class.validate!('http://224.0.0.1/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end

      it 'raises UnsafeUrlError for broadcast address' do
        expect { described_class.validate!('http://255.255.255.255/secret') }
          .to raise_error(described_class::UnsafeUrlError, /blocked range/)
      end
    end
  end
end
