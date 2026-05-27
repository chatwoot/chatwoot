# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrustedProxyCidrs do
  describe '.build_from_env' do
    it 'returns empty array for blank string' do
      expect(described_class.build_from_env('')).to eq([])
    end

    it 'returns empty array for whitespace-only entries' do
      expect(described_class.build_from_env(' ,  , ')).to eq([])
    end

    it 'parses comma-separated CIDRs' do
      result = described_class.build_from_env('10.0.0.0/8, 2001:db8::/32')
      expect(result).to all(be_a(IPAddr))
      expect(result.length).to eq(2)
    end

    it 'raises ArgumentError with a clear message for invalid CIDR' do
      expect do
        described_class.build_from_env('192.168.1.0/24,not-a-cidr')
      end.to raise_error(
        ArgumentError,
        /TRUSTED_PROXY_CIDRS contains invalid CIDR.*not-a-cidr/
      )
    end
  end
end
