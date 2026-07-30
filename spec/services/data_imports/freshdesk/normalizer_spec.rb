require 'rails_helper'

RSpec.describe DataImports::Freshdesk::Normalizer do
  let(:contact_payload) do
    JSON.parse(Rails.root.join('spec/fixtures/data_import/freshdesk/contact.json').read)
  end
  let(:ticket_fixture) do
    JSON.parse(Rails.root.join('spec/fixtures/data_import/freshdesk/ticket_with_conversations.json').read)
  end

  it 'normalizes Freshdesk contacts into the shared importer contract', :aggregate_failures do
    contact = described_class.new.contact(contact_payload)

    expect(contact).to include(
      'id' => '1001',
      'name' => 'Customer Example',
      'email' => 'customer@example.com',
      'phone' => '+15551234567',
      'external_id' => 'customer-1001',
      'other_emails' => ['billing@example.com'],
      'custom_fields' => { 'support_plan' => 'growth' },
      'tags' => ['priority']
    )
    expect(contact['created_at']).to eq(Time.zone.parse('2024-01-01T09:00:00Z').to_i)
    expect(contact['updated_at']).to eq(Time.zone.parse('2024-01-04T12:30:00Z').to_i)
  end

  it 'normalizes ticket descriptions, replies, and private notes in source order', :aggregate_failures do
    ticket = described_class.new.ticket(ticket_fixture.fetch('ticket'), ticket_fixture.fetch('conversations'))
    parts = ticket.dig('conversation_parts', 'conversation_parts')

    expect(ticket).to include(
      'id' => '2001',
      'status' => 4,
      'priority' => 2,
      'requester_id' => 1001
    )
    expect(ticket.dig('source', 'type')).to eq('email')
    expect(ticket.dig('source', 'author', 'type')).to eq('contact')
    expect(ticket.dig('contacts', 'contacts', 0, 'email')).to eq('customer@example.com')
    expect(parts.pluck('id')).to eq(%w[3001 3002 3003])
    expect(parts.pluck('part_type')).to eq(%w[comment note comment])
    expect(parts.map { |part| part.dig('author', 'type') }).to eq(%w[admin admin contact])
    expect(parts.second).to include('private' => true)
    expect(parts.second['attachments'].first).to include('name' => 'browser-log.txt')
  end

  it 'marks outbound email ticket descriptions as outgoing source messages' do
    outbound_ticket = ticket_fixture.fetch('ticket').merge('source' => 10)

    ticket = described_class.new.ticket(outbound_ticket, [])

    expect(ticket.dig('source', 'type')).to eq('outbound_email')
    expect(ticket.dig('source', 'author', 'type')).to eq('admin')
  end
end
