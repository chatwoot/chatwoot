require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS
describe Whatsapp::Providers::WhatsappD360CloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'd360_cloud', validate_provider_config: false, sync_templates: false) }
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'test', inbox: whatsapp_channel.inbox)
  end
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#api_headers' do
    it 'uses D360-API-KEY instead of Bearer' do
      expect(service.api_headers).to eq('D360-API-KEY' => 'test_key', 'Content-Type' => 'application/json')
    end
  end

  describe '#send_message' do
    it 'posts to waba-v2 /messages without phone_number_id in the path' do
      stub_request(:post, 'https://waba-v2.360dialog.io/messages')
        .with(headers: { 'D360-API-KEY' => 'test_key' })
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      expect(service.send_message('+553499793594', message)).to eq 'message_id'
    end
  end

  describe '#send_template' do
    it 'posts template payload to waba-v2 /messages' do
      stub_request(:post, 'https://waba-v2.360dialog.io/messages')
        .with(body: hash_including('type' => 'template'), headers: { 'D360-API-KEY' => 'test_key' })
        .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

      template_info = { name: 'elisa_fu_retomada', lang_code: 'pt_BR', parameters: [] }
      expect(service.send_template('+553499793594', template_info, message)).to eq 'message_id'
    end
  end

  describe '#media_url' do
    it 'builds the media lookup URL without graph version prefix' do
      expect(service.media_url('media-123')).to eq 'https://waba-v2.360dialog.io/media-123'
    end
  end

  describe '#media_download_url' do
    it 'reaponta o host da URL interna da Meta pro proxy da 360dialog' do
      original = 'https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=123&ext=456&hash=abc'
      expect(service.media_download_url(original))
        .to eq 'https://waba-v2.360dialog.io/whatsapp_business/attachments/?mid=123&ext=456&hash=abc'
    end
  end

  describe '#validate_provider_config?' do
    it 'validates against waba-v2 message_templates with the D360 header' do
      stub = stub_request(:get, 'https://waba-v2.360dialog.io/message_templates?limit=1')
             .with(headers: { 'D360-API-KEY' => 'test_key' })
             .to_return(status: 200, body: { data: [] }.to_json, headers: response_headers)

      expect(service.validate_provider_config?).to be true
      expect(stub).to have_been_requested
    end

    it 'returns false when the key is rejected' do
      stub_request(:get, 'https://waba-v2.360dialog.io/message_templates?limit=1')
        .to_return(status: 401, body: { error: 'unauthorized' }.to_json, headers: response_headers)

      expect(service.validate_provider_config?).to be false
    end
  end

  describe '#sync_templates' do
    it 'stores templates fetched with the D360 header' do
      templates = [{ 'name' => 'elisa_fu_retomada', 'status' => 'approved', 'language' => 'pt_BR' }]
      stub_request(:get, 'https://waba-v2.360dialog.io/message_templates?limit=100')
        .with(headers: { 'D360-API-KEY' => 'test_key' })
        .to_return(status: 200, body: { data: templates }.to_json, headers: response_headers)

      service.sync_templates
      expect(whatsapp_channel.reload.message_templates).to eq(templates)
    end

    it 'aceita o shape waba_templates da 360dialog' do
      templates = [{ 'name' => 'elisa_abertura_lead', 'status' => 'pending' }]
      stub_request(:get, 'https://waba-v2.360dialog.io/message_templates?limit=100')
        .to_return(status: 200, body: { waba_templates: templates }.to_json, headers: response_headers)

      service.sync_templates
      expect(whatsapp_channel.reload.message_templates).to eq(templates)
    end
  end
end
