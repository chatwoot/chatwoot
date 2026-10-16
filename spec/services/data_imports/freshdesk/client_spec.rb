require 'rails_helper'

RSpec.describe DataImports::Freshdesk::Client do
  describe '.normalize_domain' do
    it 'accepts a Freshdesk subdomain, hostname, or URL', :aggregate_failures do
      expect(described_class.normalize_domain('acme')).to eq('acme.freshdesk.com')
      expect(described_class.normalize_domain('ACME.FRESHDESK.COM')).to eq('acme.freshdesk.com')
      expect(described_class.normalize_domain('https://acme.freshdesk.com/support/home')).to eq('acme.freshdesk.com')
    end

    it 'rejects hosts outside Freshdesk' do
      expect do
        described_class.normalize_domain('acme.example.com')
      end.to raise_error(ArgumentError, 'Enter a valid Freshdesk domain, such as acme.freshdesk.com.')
    end
  end

  describe '#list_tickets' do
    it 'uses API key basic authentication, requests full history, and follows the next page link', :aggregate_failures do
      response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: [{ 'id' => 2001 }],
        headers: {
          'link' => '<https://acme.freshdesk.com/api/v2/tickets?page=3&per_page=100>; rel="next"'
        }
      )
      allow(HTTParty).to receive(:get).and_return(response)

      page = described_class.new(domain: 'acme', api_key: 'secret').list_tickets(page: 2)

      expect(HTTParty).to have_received(:get).with(
        'https://acme.freshdesk.com/api/v2/tickets',
        query: {
          page: 2,
          per_page: 100,
          updated_since: DataImports::Freshdesk::Client::EARLIEST_TICKET_TIMESTAMP
        },
        basic_auth: { username: 'secret', password: 'X' },
        headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' },
        timeout: 30
      )
      expect(page.data).to eq([{ 'id' => 2001 }])
      expect(page.next_page).to eq(3)
    end

    it 'accepts only forward pages from relative or same-domain links', :aggregate_failures do
      client = described_class.new(domain: 'acme', api_key: 'secret')

      expect(client.send(:next_page, '</api/v2/tickets?page=3>; rel="next"', current_page: 2)).to eq(3)
      expect(client.send(:next_page, '<https://acme.freshdesk.com/api/v2/tickets?page=4>; rel="next"', current_page: 3)).to eq(4)
      expect(client.send(:next_page, '<https://other.freshdesk.com/api/v2/tickets?page=4>; rel="next"', current_page: 3)).to be_nil
      expect(client.send(:next_page, '</api/v2/tickets?page=abc>; rel="next"', current_page: 2)).to be_nil
      expect(client.send(:next_page, '</api/v2/tickets?page=0>; rel="next"', current_page: 2)).to be_nil
      expect(client.send(:next_page, '</api/v2/tickets?page=2>; rel="next"', current_page: 2)).to be_nil
      expect(client.send(:next_page, '</api/v2/tickets?page=1>; rel="next"', current_page: 2)).to be_nil
      expect(client.send(:next_page, '<%%%>; rel="next"', current_page: 2)).to be_nil
    end
  end

  describe 'errors' do
    it 'exposes Freshdesk retry timing on rate limits', :aggregate_failures do
      response = instance_double(
        HTTParty::Response,
        success?: false,
        code: 429,
        parsed_response: { 'description' => 'Rate limit exceeded' },
        headers: { 'retry-after' => '42' }
      )
      allow(HTTParty).to receive(:get).and_return(response)

      expect { described_class.new(domain: 'acme', api_key: 'secret').list_contacts }.to raise_error do |error|
        expect(error.class.name).to eq('DataImports::Freshdesk::Client::RateLimitError')
        expect(error).to have_attributes(status: 429, retry_after: '42')
        expect(error.message).to eq('Rate limit exceeded')
      end
    end

    it 'wraps transport failures in a retryable client error', :aggregate_failures do
      allow(HTTParty).to receive(:get).and_raise(SocketError, 'getaddrinfo failed')

      expect { described_class.new(domain: 'acme', api_key: 'secret').list_contacts }.to raise_error do |error|
        expect(error.class.name).to eq('DataImports::Freshdesk::Client::Error')
        expect(error.message).to eq('Freshdesk API request failed before receiving a response: getaddrinfo failed')
        expect(error.body).to include(transport_error_class: 'SocketError')
      end
    end
  end
end
