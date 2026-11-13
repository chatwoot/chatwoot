require 'rails_helper'

RSpec.describe Captain::Mcp::DiscoveryService do
  let(:url) { 'https://mcp.example.com/mcp' }
  let(:connection) { instance_double(Captain::Mcp::Connection) }
  let(:challenge_headers) { {} }
  let(:unauthorized) do
    RubyLLM::UnauthorizedError.new('Unauthorized', response: instance_double(Faraday::Response, headers: challenge_headers))
  end

  before { allow(Captain::Mcp::Connection).to receive(:new).and_return(connection) }

  it 'rejects a URL Chatwoot would not save, before it connects' do
    expect { described_class.new(url: 'http://mcp.example.com/mcp').perform }
      .to raise_error(described_class::InvalidUrlError, /must use HTTPS protocol/)
    expect(Captain::Mcp::Connection).not_to have_received(:new)
  end

  it 'reports a server that answers without sign-in, with the name it gives' do
    allow(connection).to receive(:server_name).and_return('Invoicely')

    expect(described_class.new(url: url).perform).to have_attributes(auth_type: 'none', name: 'Invoicely')
  end

  it 'falls back to the host when the server gives no name' do
    allow(connection).to receive(:server_name).and_return('')

    expect(described_class.new(url: url).perform.name).to eq('mcp.example.com')
  end

  it 'reports a token server when the token works' do
    allow(connection).to receive(:server_name).and_return('Invoicely')

    expect(described_class.new(url: url, token: 'secret').perform.auth_type).to eq('token')
  end

  it 'lets a rejected token through, so the admin hears the token is wrong' do
    allow(connection).to receive(:server_name).and_raise(unauthorized)

    expect { described_class.new(url: url, token: 'wrong').perform }.to raise_error(RubyLLM::UnauthorizedError)
  end

  context 'when the server asks for sign-in' do
    before { allow(connection).to receive(:server_name).and_raise(unauthorized) }

    context 'with a resource_metadata challenge' do
      let(:challenge_headers) { { 'www-authenticate' => 'Bearer resource_metadata="https://mcp.example.com/.well-known/oauth-protected-resource"' } }

      it 'reports OAuth without probing anything' do
        allow(SafeFetch).to receive(:fetch)

        expect(described_class.new(url: url).perform).to have_attributes(auth_type: 'oauth', name: 'mcp.example.com')
        expect(SafeFetch).not_to have_received(:fetch)
      end
    end

    it 'reports OAuth when the server publishes OAuth metadata' do
      allow(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError, 'not found')
      allow(SafeFetch).to receive(:fetch).with('https://mcp.example.com/.well-known/oauth-authorization-server', any_args).and_return(true)

      expect(described_class.new(url: url).perform.auth_type).to eq('oauth')
    end

    it 'reports a token when the server publishes no OAuth metadata' do
      allow(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError, 'not found')

      expect(described_class.new(url: url).perform.auth_type).to eq('token')
      expect(SafeFetch).to have_received(:fetch).with('https://mcp.example.com/.well-known/oauth-protected-resource/mcp', any_args)
    end
  end
end
