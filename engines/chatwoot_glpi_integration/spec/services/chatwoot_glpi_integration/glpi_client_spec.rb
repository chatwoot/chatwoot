require 'rails_helper'

RSpec.describe ChatwootGlpiIntegration::GlpiClient do
  let(:account) { create(:account) }
  let(:conn)    { create(:glpi_connection, account: account) }

  before { Rails.cache.clear }

  describe '#create_ticket' do
    it 'fetches token + posts to /Ticket' do
      stub_request(:post, conn.token_endpoint)
        .to_return(status: 200, body: { access_token: 'tok' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, "#{conn.api_url}/Ticket")
        .with(headers: { 'Authorization' => 'Bearer tok' })
        .to_return(status: 201, body: { id: 99 }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      result = described_class.new(conn).create_ticket(name: 'x', content: 'y')
      expect(result['id']).to eq(99)
    end

    it 'refreshes token on 401 and retries once' do
      stub_request(:post, conn.token_endpoint)
        .to_return({ status: 200, body: { access_token: 'old' }.to_json,
                     headers: { 'Content-Type' => 'application/json' } },
                   { status: 200, body: { access_token: 'new' }.to_json,
                     headers: { 'Content-Type' => 'application/json' } })

      stub_request(:post, "#{conn.api_url}/Ticket")
        .to_return({ status: 401, body: '{}', headers: { 'Content-Type' => 'application/json' } },
                   { status: 201, body: { id: 7 }.to_json,
                     headers: { 'Content-Type' => 'application/json' } })

      result = described_class.new(conn).create_ticket(name: 'x', content: 'y')
      expect(result['id']).to eq(7)
    end
  end
end
