# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Api do
  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:channel_api) { create(:channel_api) }

    context 'when it validates webhook_url length' do
      it 'valid when within limit' do
        channel_api.webhook_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(channel_api.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        channel_api.webhook_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
        channel_api.valid?
        expect(channel_api.errors[:webhook_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe 'whatsapp web cleanup' do
    it 'removes evolution instance on destroy for whatsapp web integrations' do
      channel_api = create(
        :channel_api,
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: { instance_name: 'cw_1_77066318623' }
        }
      )
      cleanup_service = instance_double(WhatsappWeb::InstanceCleanupService, perform: true)

      expect(WhatsappWeb::InstanceCleanupService).to receive(:new).with(channel: channel_api).and_return(cleanup_service)
      expect(cleanup_service).to receive(:perform)

      channel_api.destroy!
    end

    it 'does not run cleanup for non-whatsapp web integrations' do
      channel_api = create(:channel_api, additional_attributes: { integration_type: 'api' })

      expect(WhatsappWeb::InstanceCleanupService).not_to receive(:new)

      channel_api.destroy!
    end

    it 'aborts destroy when cleanup fails' do
      channel_api = create(
        :channel_api,
        additional_attributes: {
          integration_type: 'whatsapp_web',
          whatsapp_web: { instance_name: 'cw_1_77066318623' }
        }
      )
      cleanup_service = instance_double(WhatsappWeb::InstanceCleanupService)
      error = WhatsappWeb::ConnectorClient::RequestError.new('Connector is unreachable')

      allow(WhatsappWeb::InstanceCleanupService).to receive(:new).with(channel: channel_api).and_return(cleanup_service)
      allow(cleanup_service).to receive(:perform).and_raise(error)

      expect(channel_api.destroy).to be(false)
      expect(channel_api.errors[:base]).to include('Connector is unreachable')
    end
  end
end
