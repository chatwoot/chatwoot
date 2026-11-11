require 'rails_helper'

RSpec.describe Captain::Mcp::SafeFaradayAdapter do
  let(:adapter) { described_class.new }

  # Calls ssrf_filter's private address check, so a gem update that renames it fails here
  describe '#net_http_connection' do
    it 'connects to the checked public address of the host' do
      allow(Resolv).to receive(:getaddresses).with('mcp.example.com').and_return(['93.184.216.34'])

      http = adapter.net_http_connection(url: URI('https://mcp.example.com/mcp'))

      expect(http.address).to eq('mcp.example.com')
      expect(http.ipaddr).to eq('93.184.216.34')
    end

    it 'raises UnsafeUrlError when the host resolves only to private addresses' do
      allow(Resolv).to receive(:getaddresses).with('internal.example.com').and_return(['10.0.0.5'])

      expect { adapter.net_http_connection(url: URI('https://internal.example.com/mcp')) }.to raise_error do |error|
        expect(error.class.name).to eq('SafeFetch::UnsafeUrlError')
      end
    end
  end
end
