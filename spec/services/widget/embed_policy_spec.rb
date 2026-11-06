require 'rails_helper'

RSpec.describe Widget::EmbedPolicy do
  describe '#frame_ancestors_source' do
    it 'joins the configured domains, trimming blanks' do
      policy = described_class.new(' example.com, https://app.example.com , ')
      expect(policy.frame_ancestors_source).to eq('example.com https://app.example.com')
    end

    it 'is empty when nothing is configured' do
      expect(described_class.new(nil).frame_ancestors_source).to eq('')
    end
  end

  describe '#allows_origin?' do
    subject(:policy) { described_class.new(allowed_domains) }

    # allowed_domains is host-only by convention ("example.com"), while the
    # browser sends Origin with a scheme.
    context 'with a host-only domain' do
      let(:allowed_domains) { 'embed.example.com' }

      it 'matches the same host regardless of the request scheme default' do
        expect(policy.allows_origin?('https://embed.example.com', request_scheme: 'http')).to be(true)
      end

      it 'rejects a different host' do
        expect(policy.allows_origin?('https://evil.example.com', request_scheme: 'https')).to be(false)
      end

      it 'rejects a look-alike suffix host' do
        expect(policy.allows_origin?('https://embed.example.com.evil.com', request_scheme: 'https')).to be(false)
      end

      it 'enforces the install scheme on an https request' do
        expect(policy.allows_origin?('http://embed.example.com', request_scheme: 'https')).to be(false)
      end

      it 'rejects a non-default port' do
        expect(policy.allows_origin?('https://embed.example.com:444', request_scheme: 'https')).to be(false)
      end
    end

    context 'with a scheme-pinned domain' do
      let(:allowed_domains) { 'https://embed.example.com' }

      it 'requires the pinned scheme' do
        expect(policy.allows_origin?('http://embed.example.com', request_scheme: 'http')).to be(false)
        expect(policy.allows_origin?('https://embed.example.com', request_scheme: 'http')).to be(true)
      end
    end

    context 'with a "*." wildcard domain' do
      let(:allowed_domains) { '*.example.com' }

      it 'matches a subdomain but not the apex' do
        expect(policy.allows_origin?('https://app.example.com', request_scheme: 'https')).to be(true)
        expect(policy.allows_origin?('https://example.com', request_scheme: 'https')).to be(false)
      end

      it 'rejects a look-alike host outside the wildcard domain' do
        expect(policy.allows_origin?('https://app.example.com.evil.com', request_scheme: 'https')).to be(false)
      end
    end

    context 'with blank config or malformed input' do
      it 'allows nothing when no domains are configured' do
        expect(described_class.new('').allows_origin?('https://example.com', request_scheme: 'https')).to be(false)
      end

      it 'rejects a malformed origin' do
        expect(described_class.new('example.com').allows_origin?('::not a uri::', request_scheme: 'https')).to be(false)
      end
    end
  end
end
