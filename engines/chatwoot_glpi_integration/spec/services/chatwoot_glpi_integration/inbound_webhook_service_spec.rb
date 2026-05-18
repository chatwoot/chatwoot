require 'rails_helper'

RSpec.describe ChatwootGlpiIntegration::InboundWebhookService do
  let(:account)    { create(:account) }
  let(:connection) { create(:glpi_connection, account: account, webhook_secret: 'secret') }

  let(:body)      { { 'ticket_id' => 42, 'status' => 5 }.to_json }
  let(:signature) { OpenSSL::HMAC.hexdigest('SHA256', 'secret', body) }

  it 'rejects bad signature' do
    expect {
      described_class.new(connection: connection, raw_body: body,
                          signature: 'bad', payload: JSON.parse(body)).call
    }.to raise_error(described_class::InvalidSignature)
  end

  it 'returns :no_link when ticket is unknown' do
    result = described_class.new(connection: connection, raw_body: body,
                                 signature: signature, payload: JSON.parse(body)).call
    expect(result).to eq(:no_link)
  end

  it 'enqueues SyncTicketJob when link exists' do
    card = create(:kanban_card, column: create(:kanban_board, account: account).columns.first)
    create(:glpi_ticket_link, account: account, glpi_ticket_id: 42, kanban_card: card)

    expect {
      described_class.new(connection: connection, raw_body: body,
                          signature: signature, payload: JSON.parse(body)).call
    }.to have_enqueued_job(ChatwootGlpiIntegration::SyncTicketJob)
  end
end
