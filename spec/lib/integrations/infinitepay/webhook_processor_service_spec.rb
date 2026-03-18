require 'rails_helper'

describe Integrations::Infinitepay::WebhookProcessorService do
  describe '#build_event_payload' do
    before do
      allow_any_instance_of(Account).to receive(:enable_default_features)
    end

    let(:account) { create(:account) }
    let(:contact) do
      create(
        :contact,
        :with_email,
        account: account,
        phone_number: '+5511999999999',
        identifier: 'jm_client_existing-123',
        custom_attributes: { 'document' => '12345678900' },
        additional_attributes: { 'source' => 'chatwit' }
      )
    end
    let(:inbox) { create(:inbox, account: account, name: 'WhatsApp Inbox') }
    let(:conversation) do
      create(
        :conversation,
        account: account,
        inbox: inbox,
        contact: contact,
        cached_label_list: 'jusmonitoria_monitoramento,cliente_ativo'
      )
    end
    let(:payment_link) do
      PaymentLink.create!(
        account: account,
        conversation: conversation,
        order_nsu: 'chatwit-1-456-abc123',
        amount_cents: 1000,
        paid_amount_cents: 1010,
        capture_method: 'pix',
        receipt_url: 'https://comprovante.com/123',
        description: 'Pagamento de teste',
        checkout_url: 'https://checkout.example.com/123',
        status: 'paid'
      )
    end

    subject(:event_payload) { described_class.new({}).send(:build_event_payload, payment_link) }

    it 'includes full contact context and minimal conversation context' do
      expect(event_payload[:payment_link_id]).to eq(payment_link.id)
      expect(event_payload[:order_nsu]).to eq(payment_link.order_nsu)
      expect(event_payload[:conversation_id]).to eq(conversation.id)

      expect(event_payload[:contact]).to include(
        id: contact.id,
        name: contact.name,
        email: contact.email,
        phone_number: contact.phone_number,
        identifier: contact.identifier,
        custom_attributes: contact.custom_attributes,
        additional_attributes: contact.additional_attributes
      )
      expect(event_payload[:contact][:account]).to include(id: account.id, name: account.name)

      expect(event_payload[:conversation]).to include(
        id: conversation.display_id,
        status: conversation.status
      )
      expect(event_payload[:conversation][:labels]).to eq(%w[jusmonitoria_monitoramento cliente_ativo])
      expect(event_payload[:conversation][:contact]).to include(id: contact.id, name: contact.name)
      expect(event_payload[:conversation][:inbox]).to include(id: inbox.id, name: inbox.name, channel_type: inbox.channel_type)

      expect(event_payload[:inbox]).to eq(
        id: inbox.id,
        name: inbox.name,
        channel_type: inbox.channel_type
      )
    end
  end
end