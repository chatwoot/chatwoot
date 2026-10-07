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

  describe '#list_conversations' do
    it 'returns a resumable ticket chunk with a cursor after every ticket', :aggregate_failures do
      tickets = Array.new(25) { |index| { 'id' => index + 1, 'source' => 1 } }
      allow(client).to receive(:list_tickets).with(page: 2, per_page: 100).and_return(
        DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: 3)
      )

      response = source.list_conversations(
        starting_after: { 'page' => 2, 'offset' => 10 },
        per_page: 100
      )

      expect(response['data'].pluck('id')).to eq((11..20).map(&:to_s))
      expect(response.dig('pages', 'checkpoints').first).to include('page' => 2, 'offset' => 11, 'next_page' => 3)
      expect(response.dig('pages', 'checkpoints').last).to include('page' => 2, 'offset' => 20, 'next_page' => 3)
      expect(response.dig('pages', 'next', 'starting_after')).to include('page' => 2, 'offset' => 20, 'next_page' => 3)
    end

    it 'reuses the cached ticket page before advancing to the next Freshdesk page', :aggregate_failures do
      tickets = Array.new(25) { |index| { 'id' => index + 1, 'source' => 1 } }
      expect(client).to receive(:list_tickets).with(page: 2, per_page: 100).once.and_return(
        DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: 3)
      )

      first_chunk = source.list_conversations(
        starting_after: { 'page' => 2, 'offset' => 10 },
        per_page: 100
      )
      response = source.list_conversations(starting_after: first_chunk.dig('pages', 'next', 'starting_after'), per_page: 100)

      expect(response['data'].pluck('id')).to eq((21..25).map(&:to_s))
      expect(response.dig('pages', 'checkpoints').last).to eq('page' => 3, 'offset' => 0)
      expect(response.dig('pages', 'next', 'starting_after')).to eq('page' => 3, 'offset' => 0)
    end

    it 'reports the REST ticket limit only after the final chunk of a full page 300', :aggregate_failures do
      tickets = Array.new(100) { |index| { 'id' => index + 1, 'source' => 1 } }
      expect(client).to receive(:list_tickets).with(page: 300, per_page: 100).once.and_return(
        DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: nil)
      )

      first_chunk = source.list_conversations(starting_after: { 'page' => 300, 'offset' => 0 }, per_page: 100)
      final_cursor = first_chunk.dig('pages', 'current', 'starting_after').merge('offset' => 90)
      final_chunk = source.list_conversations(starting_after: final_cursor, per_page: 100)

      expect(first_chunk.dig('pages', 'limit_reached')).to be(false)
      expect(final_chunk['data'].pluck('id')).to eq((91..100).map(&:to_s))
      expect(final_chunk.dig('pages', 'next')).to be_nil
      expect(final_chunk.dig('pages', 'limit_reached')).to be(true)
    end

    it 'completes a partial page 300 without reporting the ticket limit' do
      tickets = Array.new(99) { |index| { 'id' => index + 1, 'source' => 1 } }
      allow(client).to receive(:list_tickets).with(page: 300, per_page: 100).and_return(
        DataImports::Freshdesk::Client::Page.new(data: tickets, next_page: nil)
      )

      response = source.list_conversations(starting_after: { 'page' => 300, 'offset' => 90 }, per_page: 100)

      expect(response.dig('pages', 'next')).to be_nil
      expect(response.dig('pages', 'limit_reached')).to be(false)
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
