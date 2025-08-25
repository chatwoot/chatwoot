require 'rails_helper'

RSpec.describe Webhooks::WhatsappEventsJob do
  subject(:job) { described_class }

  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:params)  do
    {
      object: 'whatsapp_business_account',
      phone_number: channel.phone_number,
      entry: [{
        changes: [
          {
            value: {
              metadata: {
                phone_number_id: channel.provider_config['phone_number_id'],
                display_phone_number: channel.phone_number.delete('+')
              }
            }
          }
        ]
      }]
    }
  end
  let(:process_service) { double }

  before do
    allow(process_service).to receive(:perform)
  end

  it 'enqueues the job' do
    expect { job.perform_later(params) }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('low')
  end

  context 'when whatsapp_cloud provider' do
    it 'enqueue Whatsapp::IncomingMessageWhatsappCloudService' do
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).to receive(:create).with(
        channel: channel,
        params: hash_including(params),
        correlation_id: anything
      )
      job.perform_now(params)
    end

    it 'will not enqueue message jobs based on phone number in the URL if the entry payload is not present' do
      params = {
        object: 'whatsapp_business_account',
        phone_number: channel.phone_number,
        entry: [{ changes: [{}] }]
      }
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create)

      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)
      job.perform_now(params)
    end

    it 'will not enqueue Whatsapp::IncomingMessageWhatsappCloudService if channel reauthorization required' do
      channel.prompt_reauthorization!
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)
      job.perform_now(params)
    end

    it 'will not enqueue if channel is not present' do
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)

      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)
      job.perform_now(phone_number: 'random_phone_number')
    end

    it 'will not enqueue Whatsapp::IncomingMessageWhatsappCloudService if account is suspended' do
      account = channel.account
      account.update!(status: :suspended)
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)

      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)
      job.perform_now(params)
    end

    it 'logs a warning when channel is inactive' do
      channel.prompt_reauthorization!
      allow(Rails.logger).to receive(:warn)

      expect(Rails.logger).to receive(:warn).with("Inactive WhatsApp channel: #{channel.phone_number}")
      job.perform_now(params)
    end

    it 'logs a warning with unknown phone number when channel does not exist' do
      unknown_phone = '+1234567890'
      allow(Rails.logger).to receive(:warn)

      expect(Rails.logger).to receive(:warn).with("Inactive WhatsApp channel: unknown - #{unknown_phone}")
      job.perform_now(phone_number: unknown_phone)
    end
  end

  context 'when default provider' do
    it 'enqueue Whatsapp::IncomingMessageService' do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      channel.update(provider: 'default')
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).to receive(:create).with(
        channel: channel,
        params: hash_including(params),
        correlation_id: anything
      )
      job.perform_now(params)
    end
  end

  context 'when whapi provider' do
    let!(:whapi_channel) do
      create(:channel_whatsapp,
             provider: 'whapi',
             phone_number: 'pending:TEST_CHANNEL_ID',
             provider_config: {
               'whapi_channel_id' => 'TEST_CHANNEL_ID',
               'whapi_channel_token' => 'test_token',
               'connection_status' => 'pending'
             },
             sync_templates: false,
             validate_provider_config: false)
    end
    let(:whapi_message_params) do
      {
        channel_id: 'TEST_CHANNEL_ID',
        messages: [{
          id: 'msg_123',
          from: '1234567890',
          type: 'text',
          text: { body: 'Hello World' }
        }]
      }
    end
    let(:whapi_connected_params) do
      {
        channel_id: 'TEST_CHANNEL_ID',
        events: [{
          type: 'connected',
          phone: '1234567890'
        }]
      }
    end

    before do
      # Stub the webhook update service to prevent external calls
      allow_any_instance_of(Whatsapp::Partner::WhapiPartnerService).to receive(:update_webhook_with_phone_number)
        .and_return('https://test-webhook-url.com')

      # Stub ActionCable to prevent broadcast errors
      allow(ActionCable.server).to receive(:broadcast)

      # Stub ActiveSupport::Notifications to prevent instrumentation errors
      allow(ActiveSupport::Notifications).to receive(:instrument)
    end

    it 'does not process when whapi_channel_id is not found' do
      params_with_unknown_id = whapi_message_params.merge(channel_id: 'UNKNOWN_ID')

      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create)
      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)

      job.perform_now(params_with_unknown_id)
    end

    it 'processes whapi messages using factory pattern' do
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).to receive(:create).with(
        channel: whapi_channel,
        params: hash_including(whapi_message_params),
        correlation_id: anything
      )
      job.perform_now(whapi_message_params)
    end
  end

  context 'when whatsapp business params' do
    it 'enqueue Whatsapp::IncomingMessageWhatsappCloudService based on the number in payload' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: {
                    phone_number_id: other_channel.provider_config['phone_number_id'],
                    display_phone_number: other_channel.phone_number.delete('+')
                  }
                }
              }
            ]
          }
        ]
      }
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).to receive(:create).with(
        channel: other_channel,
        params: hash_including(wb_params),
        correlation_id: anything
      )
      job.perform_now(wb_params)
    end

    it 'Ignore reaction type message and stop raising error' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Test Test' }, wa_id: '1111981136571' }],
              messages: [{
                from: '1111981136571', reaction: { emoji: '👍' }, timestamp: '1664799904', type: 'reaction'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Message, :count)
    end

    it 'ignore reaction type message, would not create contact if the reaction is the first event' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Test Test' }, wa_id: '1111981136571' }],
              messages: [{
                from: '1111981136571', reaction: { emoji: '👍' }, timestamp: '1664799904', type: 'reaction'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Contact, :count)
    end

    it 'ignore request_welcome type message, would not create contact or conversation' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              messages: [{
                from: '1111981136571', timestamp: '1664799904', type: 'request_welcome'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Contact, :count)

      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Conversation, :count)
    end

    it 'will not enque Whatsapp::IncomingMessageWhatsappCloudService when invalid phone number id' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: {
                    phone_number_id: 'random phone number id',
                    display_phone_number: other_channel.phone_number.delete('+')
                  }
                }
              }
            ]
          }
        ]
      }
      allow(Whatsapp::IncomingMessageServiceFactory).to receive(:create).and_return(process_service)
      expect(Whatsapp::IncomingMessageServiceFactory).not_to receive(:create)
      job.perform_now(wb_params)
    end
  end
end
