require 'rails_helper'

describe Whatsapp::Providers::WhatsappYcloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:ycloud_api_base) { 'https://api.ycloud.com/v2' }

  describe '#mark_as_read' do
    it 'sends markAsRead request' do
      stub = stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/markAsRead")
        .with(body: { messageId: 'wamid.123', to: whatsapp_channel.phone_number }.to_json)
        .to_return(status: 200, body: '{}', headers: response_headers)

      service.mark_as_read('wamid.123')
      expect(stub).to have_been_requested
    end
  end

  describe '#send_typing_indicator' do
    it 'sends typing indicator' do
      stub = stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/sendDirectly")
        .with(body: {
          from: whatsapp_channel.phone_number,
          to: '+1234567890',
          type: 'typing'
        }.to_json)
        .to_return(status: 200, body: '{}', headers: response_headers)

      service.send_typing_indicator('+1234567890')
      expect(stub).to have_been_requested
    end
  end

  describe '#upload_media' do
    it 'uploads media and returns media ID' do
      stub = stub_request(:post, "#{ycloud_api_base}/whatsapp/media/upload")
        .to_return(status: 200, body: { id: 'media_001' }.to_json, headers: response_headers)

      file = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      result = service.upload_media(file, 'image/png')
      expect(stub).to have_been_requested
      expect(result).to eq('media_001')
    end

    it 'returns nil when upload fails' do
      stub_request(:post, "#{ycloud_api_base}/whatsapp/media/upload")
        .to_return(status: 400, body: { errorMessage: 'Bad request' }.to_json, headers: response_headers)

      file = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      expect(service.upload_media(file, 'image/png')).to be_nil
    end
  end

  describe '#send_message_async' do
    let(:message) { create(:message, message_type: :outgoing, content: 'async test', inbox: whatsapp_channel.inbox) }

    it 'sends via /send (enqueue) endpoint instead of /sendDirectly' do
      stub = stub_request(:post, "#{ycloud_api_base}/whatsapp/messages/send")
        .with(body: hash_including({ 'from' => whatsapp_channel.phone_number, 'to' => '+1234567890', 'type' => 'text' }))
        .to_return(status: 200, body: { id: 'enq_001' }.to_json, headers: response_headers)

      result = service.send_message_async('+1234567890', message)
      expect(stub).to have_been_requested
      expect(result).to eq('enq_001')
    end
  end

  describe 'service accessors' do
    it 'returns template service' do
      expect(service.template_service).to be_a(Whatsapp::Ycloud::TemplateService)
    end

    it 'returns flow service' do
      expect(service.flow_service).to be_a(Whatsapp::Ycloud::FlowService)
    end

    it 'returns call service' do
      expect(service.call_service).to be_a(Whatsapp::Ycloud::CallService)
    end

    it 'returns profile service' do
      expect(service.profile_service).to be_a(Whatsapp::Ycloud::ProfileService)
    end

    it 'returns contact service' do
      expect(service.contact_service).to be_a(Whatsapp::Ycloud::ContactService)
    end

    it 'returns event service' do
      expect(service.event_service).to be_a(Whatsapp::Ycloud::EventService)
    end

    it 'returns multi_channel service' do
      expect(service.multi_channel_service).to be_a(Whatsapp::Ycloud::MultiChannelService)
    end

    it 'returns unsubscriber service' do
      expect(service.unsubscriber_service).to be_a(Whatsapp::Ycloud::UnsubscriberService)
    end

    it 'returns webhook service' do
      expect(service.webhook_service).to be_a(Whatsapp::Ycloud::WebhookService)
    end

    it 'returns account service' do
      expect(service.account_service).to be_a(Whatsapp::Ycloud::AccountService)
    end
  end

  describe 'webhook registration with ALL_EVENTS' do
    it 'registers webhook with all 25 event types during validation' do
      stub_request(:get, "#{ycloud_api_base}/whatsapp/templates?limit=1")
        .to_return(status: 200, body: { items: [] }.to_json, headers: response_headers)
      webhook_stub = stub_request(:post, "#{ycloud_api_base}/webhookEndpoints")
        .with(body: hash_including({ 'events' => Whatsapp::Ycloud::WebhookService::ALL_EVENTS }))
        .to_return(status: 200, body: { id: 'wh_001' }.to_json, headers: response_headers)

      service.validate_provider_config?
      expect(webhook_stub).to have_been_requested
    end
  end
end
