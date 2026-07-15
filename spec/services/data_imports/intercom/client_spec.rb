require 'rails_helper'

RSpec.describe DataImports::Intercom::Client do
  let(:client) { described_class.new(access_token: 'intercom-token') }

  describe '#list_contacts' do
    it 'wraps transport failures in a retryable client error', :aggregate_failures do
      allow(HTTParty).to receive(:get).and_raise(SocketError, 'getaddrinfo failed')

      expect { client.list_contacts }.to raise_error(DataImports::Intercom::Client::Error) do |error|
        expect(error.message).to eq('Intercom API request failed before receiving a response: getaddrinfo failed')
        expect(error.body).to include(transport_error_class: 'SocketError')
      end
    end
  end
end
