require 'rails_helper'

RSpec.describe DataImports::Intercom::Client do
  let(:client) { described_class.new(access_token: 'intercom-token') }

  describe '#list_contacts' do
    it 'wraps transport failures in a retryable client error', :aggregate_failures do
      allow(HTTParty).to receive(:get).and_raise(SocketError, 'getaddrinfo failed')

      expect { client.list_contacts }.to raise_error do |error|
        expect(error.class.name).to eq('DataImports::Intercom::Client::Error')
        expect(error.message).to eq('Intercom API request failed before receiving a response: getaddrinfo failed')
        expect(error.body).to include(transport_error_class: 'SocketError')
      end
    end

    # `Net::HTTP` repeats an idempotent request once by default, so the 30 seconds this
    # client advertises were 60 against a server that accepts the connection and then
    # stops answering, once per page of an import that pages.
    it 'asks once, so the ceiling it advertises is the one it spends' do
      response = instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => [] })
      options = nil
      allow(HTTParty).to receive(:get) do |_url, **kwargs|
        options = kwargs
        response
      end

      client.list_contacts

      expect(options).to include(timeout: 30, max_retries: 0)
    end
  end
end
