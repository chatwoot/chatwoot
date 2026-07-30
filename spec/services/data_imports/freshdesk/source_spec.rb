require 'rails_helper'

RSpec.describe DataImports::Freshdesk::Source do
  let(:client) { instance_double(DataImports::Freshdesk::Client) }
  let(:ticket_fixture) do
    JSON.parse(Rails.root.join('spec/fixtures/data_import/freshdesk/ticket_with_conversations.json').read)
  end
  let(:source) do
    described_class.new(
      access_token: 'freshdesk-api-key',
      source_metadata: { domain: 'acme.freshdesk.com' }
    )
  end

  before do
    allow(DataImports::Freshdesk::Client).to receive(:new).with(
      domain: 'acme.freshdesk.com',
      api_key: 'freshdesk-api-key'
    ).and_return(client)
  end

  describe '.source_metadata' do
    it 'stores only a normalized Freshdesk domain' do
      expect(described_class.source_metadata(domain: 'https://ACME.freshdesk.com/support/home')).to eq(
        domain: 'acme.freshdesk.com'
      )
    end
  end

  describe '#list_contacts' do
    it 'normalizes records and translates numeric pages into shared cursors' do
      allow(client).to receive(:list_contacts).with(page: 2, per_page: 100).and_return(
        DataImports::Freshdesk::Client::Page.new(
          data: [{ 'id' => 1001, 'email' => 'customer@example.com' }],
          next_page: 3
        )
      )

      response = source.list_contacts(starting_after: 2, per_page: 100)

      expect(response.dig('data', 0)).to include('id' => '1001', 'email' => 'customer@example.com')
      expect(response.dig('pages', 'next', 'starting_after')).to eq(3)
    end
  end

  describe '#retrieve_conversation' do
    it 'retrieves every conversation page and normalizes the ticket', :aggregate_failures do
      conversations = ticket_fixture.fetch('conversations')
      allow(client).to receive(:retrieve_ticket).with('2001').and_return(ticket_fixture.fetch('ticket'))
      allow(client).to receive(:list_conversations).with('2001', page: 1, per_page: 100).and_return(
        DataImports::Freshdesk::Client::Page.new(data: conversations.first(2), next_page: 2)
      )
      allow(client).to receive(:list_conversations).with('2001', page: 2, per_page: 100).and_return(
        DataImports::Freshdesk::Client::Page.new(data: conversations.last(1), next_page: nil)
      )

      ticket = source.retrieve_conversation('2001')

      expect(ticket['id']).to eq('2001')
      expect(ticket.dig('conversation_parts', 'total_count')).to eq(3)
      expect(ticket.dig('conversation_parts', 'conversation_parts').pluck('id')).to eq(%w[3001 3002 3003])
    end
  end
end
