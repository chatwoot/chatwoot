require 'rails_helper'

describe Whatsapp::IncomingMessageYcloudService do
  let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }

  describe 'order message handling' do
    let(:params) do
      {
        type: 'whatsapp.inbound_message.received',
        whatsappInboundMessage: {
          id: 'msg_order_001',
          wamid: 'wamid.order001',
          from: '2423423243',
          to: whatsapp_channel.phone_number.delete('+'),
          customerProfile: { name: 'Order Customer' },
          type: 'order',
          order: {
            catalogId: 'cat_001',
            productItems: [
              { productRetailerId: 'SKU-001', quantity: 2, itemPrice: '19.99', currency: 'USD' },
              { productRetailerId: 'SKU-002', quantity: 1, itemPrice: '9.99', currency: 'USD' }
            ]
          }
        }
      }.with_indifferent_access
    end

    it 'creates message with formatted order text' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      message = whatsapp_channel.inbox.messages.first
      expect(message.content).to include('Order received:')
      expect(message.content).to include('SKU-001: 2x 19.99 USD')
      expect(message.content).to include('SKU-002: 1x 9.99 USD')
    end
  end

  describe 'product inquiry handling' do
    let(:params) do
      {
        type: 'whatsapp.inbound_message.received',
        whatsappInboundMessage: {
          id: 'msg_inquiry_001',
          wamid: 'wamid.inquiry001',
          from: '2423423243',
          to: whatsapp_channel.phone_number.delete('+'),
          customerProfile: { name: 'Inquiry Customer' },
          type: 'product_inquiry',
          productInquiry: { productRetailerId: 'SKU-123' }
        }
      }.with_indifferent_access
    end

    it 'creates message with product inquiry text' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      message = whatsapp_channel.inbox.messages.first
      expect(message.content).to include('Product inquiry: SKU-123')
    end
  end

  describe 'template reviewed event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.template.reviewed',
        whatsappTemplate: {
          name: 'hello_world',
          language: 'en',
          status: 'APPROVED'
        }
      }.with_indifferent_access
    end

    it 'does not create messages and logs event' do
      allow(Rails.logger).to receive(:info)

      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      expect(whatsapp_channel.inbox.messages.count).to eq(0)
      expect(Rails.logger).to have_received(:info).with(/Template 'hello_world' reviewed/)
    end
  end

  describe 'business account event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.business_account.updated',
        whatsappBusinessAccount: {
          id: 'waba_001',
          accountReviewStatus: 'APPROVED'
        }
      }.with_indifferent_access
    end

    it 'stores event in channel config' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      config = whatsapp_channel.reload.provider_config
      expect(config['last_events']['business_account_update']['waba_id']).to eq('waba_001')
      expect(config['last_events']['business_account_update']['status']).to eq('APPROVED')
    end
  end

  describe 'phone number quality event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.phone_number.quality_updated',
        whatsappPhoneNumber: {
          phoneNumber: whatsapp_channel.phone_number,
          qualityRating: 'GREEN',
          messagingLimit: 'TIER_1K'
        }
      }.with_indifferent_access
    end

    it 'stores quality data in channel config' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      config = whatsapp_channel.reload.provider_config
      expect(config['last_events']['phone_number_quality_update']['quality_rating']).to eq('GREEN')
      expect(config['last_events']['phone_number_quality_update']['messaging_limit']).to eq('TIER_1K')
    end
  end

  describe 'call event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.call.connect',
        whatsappCall: {
          id: 'call_001',
          status: 'ringing',
          from: '+1234567890',
          to: whatsapp_channel.phone_number
        }
      }.with_indifferent_access
    end

    it 'stores call event in channel config' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      config = whatsapp_channel.reload.provider_config
      expect(config['last_events']['call_event']['call_id']).to eq('call_001')
      expect(config['last_events']['call_event']['status']).to eq('ringing')
    end
  end

  describe 'flow status change event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.flow.status_change',
        whatsappFlow: {
          id: 'flow_001',
          status: 'PUBLISHED'
        }
      }.with_indifferent_access
    end

    it 'stores flow status in channel config' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      config = whatsapp_channel.reload.provider_config
      expect(config['last_events']['flow_status_change']['flow_id']).to eq('flow_001')
      expect(config['last_events']['flow_status_change']['status']).to eq('PUBLISHED')
    end
  end

  describe 'payment event' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.payment.updated',
        whatsappPayment: {
          referenceId: 'pay_001',
          status: 'captured',
          amount: '29.99',
          currency: 'USD'
        }
      }.with_indifferent_access
    end

    it 'stores payment event' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      config = whatsapp_channel.reload.provider_config
      expect(config['last_events']['payment_update']['reference_id']).to eq('pay_001')
      expect(config['last_events']['payment_update']['status']).to eq('captured')
    end
  end

  describe 'unsubscribe event' do
    let!(:contact) { create(:contact, phone_number: '+2423423243', account: whatsapp_channel.account) }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: whatsapp_channel.inbox) }

    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'contact.unsubscribe.created',
        unsubscriber: {
          customer: '+2423423243',
          channel: 'whatsapp'
        }
      }.with_indifferent_access
    end

    it 'updates contact custom attributes with unsubscribe status' do
      described_class.new(inbox: whatsapp_channel.inbox, params: params).perform

      contact.reload
      expect(contact.custom_attributes['whatsapp_unsubscribed_whatsapp']).to be true
    end
  end

  describe 'unknown event type' do
    let(:params) do
      {
        phone_number: whatsapp_channel.phone_number,
        type: 'whatsapp.some_future_event'
      }.with_indifferent_access
    end

    it 'logs and does not raise error' do
      allow(Rails.logger).to receive(:info)

      expect { described_class.new(inbox: whatsapp_channel.inbox, params: params).perform }.not_to raise_error
      expect(Rails.logger).to have_received(:info).with(/Unhandled webhook event type/)
    end
  end
end
