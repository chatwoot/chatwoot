# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crm::Zoho::TicketUrlAttachmentJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:ticket)  { create(:ticket, :with_external_ids, account: account, contact: contact) }
  let(:hook) do
    account.enable_features('crm_integration')
    create(:integrations_hook,
           app_id: 'zoho',
           account: account,
           settings: {
             'client_id' => 'client_123', 'client_secret' => 'secret_abc', 'soid' => 'soid_xyz',
             'access_token' => 'token_abc', 'api_domain' => 'https://www.zohoapis.eu',
             'desk_soid' => 'org_123'
           })
  end

  before { allow(Crm::SetupJob).to receive(:perform_later) }

  let(:image_url) { 'https://example.jpeg' }

  before do
    stub_request(:get, image_url)
      .to_return(status: 200, body: 'fake-jpeg-content', headers: { 'Content-Type' => 'image/jpeg' })
  end

  describe '#perform' do
    context 'when ticket has a Zoho external ID' do
      let(:ticket_client) { instance_double(Crm::Zoho::Api::TicketClient) }

      before do
        allow(Crm::Zoho::Api::TicketClient).to receive(:new).and_return(ticket_client)
        allow(ticket_client).to receive(:upload_attachment).and_return({ 'id' => 'zoho_attach_001' })
      end

      it 'downloads the file and attaches it to the ticket' do
        expect {
          described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)
        }.to change { ticket.reload.files.count }.by(1)
      end

      it 'uploads the attachment to Zoho Desk with the correct ticket ID' do
        described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)

        expect(ticket_client).to have_received(:upload_attachment).with('12345', anything)
      end

      it 'stores the Zoho attachment ID in ticket metadata' do
        described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)

        ticket.reload
        expect(ticket.metadata['zoho_attachments'].values).to include('zoho_attach_001')
      end

      it 'uses the filename from the URL' do
        described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)

        expect(ticket.reload.files.first.filename.to_s).to eq('pexels-photo-7454385.jpeg')
      end
    end

    context 'when ticket has no Zoho external ID' do
      let(:ticket) { create(:ticket, account: account, contact: contact) }

      it 'does not attach any file or call Zoho' do
        expect(Crm::Zoho::Api::TicketClient).not_to receive(:new)

        described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)

        expect(ticket.files).not_to be_attached
      end
    end

    context 'when the URL returns a non-success response' do
      before do
        stub_request(:get, image_url).to_return(status: 404, body: 'Not Found')
      end

      it 'does not attach any file' do
        described_class.new.perform(ticket_id: ticket.id, url: image_url, hook_id: hook.id)

        expect(ticket.reload.files).not_to be_attached
      end
    end
  end
end
