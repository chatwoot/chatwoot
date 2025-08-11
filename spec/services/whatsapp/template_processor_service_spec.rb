require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end

  let(:approved_template) do
    {
      'name' => 'order_update',
      'namespace' => 'ns_1',
      'language' => 'en_US',
      'status' => 'approved',
      'parameter_format' => 'NAMED',
      'components' => [
        { 'type' => 'HEADER', 'format' => 'IMAGE' },
        { 'type' => 'BODY', 'text' => 'Hi {{first_name}}, your order {{order_id}} is ready.' },
        { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'URL' }, { 'type' => 'QUICK_REPLY' }] }
      ]
    }
  end

  before do
    whatsapp_channel.update!(message_templates: [approved_template])
  end

  describe '#call with template_params' do
    it 'builds components for header image and url button' do
      template_params = {
        'name' => 'order_update',
        'language' => 'en_US',
        'processed_params' => { 'first_name' => 'Jane', 'order_id' => '123' },
        'header' => { 'type' => 'image', 'url' => 'https://example.com/img.jpg' },
        'buttons' => [{ 'type' => 'URL', 'url_suffix' => '123' }]
      }

      result = described_class.new(channel: whatsapp_channel, template_params: template_params, message: nil).call

      expect(result).to have(5).items
      name, namespace, language, params, components = result

      expect(name).to eq('order_update')
      expect(namespace).to eq('ns_1')
      expect(language).to eq('en_US')
      expect(params).to include(hash_including(type: 'text', parameter_name: 'first_name', text: 'Jane'))
      expect(components).to include(
        hash_including(type: 'header', parameters: hash_including(type: 'image', image: hash_including(link: 'https://example.com/img.jpg'))),
        hash_including(type: 'button', sub_type: 'url', index: '0', parameters: hash_including(type: 'text', text: '123'))
      )
    end

    it 'handles text header type' do
      template_params = {
        'name' => 'order_update',
        'language' => 'en_US',
        'processed_params' => { 'first_name' => 'Jane' },
        'header' => { 'type' => 'text', 'text' => 'Order Update' }
      }

      result = described_class.new(channel: whatsapp_channel, template_params: template_params, message: nil).call
      _, _, _, _, components = result

      expect(components).to include(
        hash_including(type: 'header', parameters: hash_including(type: 'text', text: 'Order Update'))
      )
    end

    it 'handles footer text' do
      template_params = {
        'name' => 'order_update',
        'language' => 'en_US',
        'processed_params' => { 'first_name' => 'Jane' },
        'footer' => { 'text' => 'Thank you for your business!' }
      }

      result = described_class.new(channel: whatsapp_channel, template_params: template_params, message: nil).call
      _, _, _, _, components = result

      expect(components).to include(
        hash_including(type: 'footer', parameters: hash_including(type: 'text', text: 'Thank you for your business!'))
      )
    end

    it 'handles flow button type' do
      template_params = {
        'name' => 'order_update',
        'language' => 'en_US',
        'processed_params' => { 'first_name' => 'Jane' },
        'buttons' => [{ 'type' => 'FLOW', 'flow_id' => 'flow_123', 'params' => { 'step' => 'checkout' } }]
      }

      result = described_class.new(channel: whatsapp_channel, template_params: template_params, message: nil).call
      _, _, _, _, components = result

      expect(components).to include(
        hash_including(type: 'button', sub_type: 'flow', index: '0',
                       parameters: hash_including(type: 'payload', payload: hash_including(flow_id: 'flow_123', data: { 'step' => 'checkout' })))
      )
    end
  end

  describe '#call without template_params' do
    let(:message) { create(:message, account: account, content: 'Hi Jane, your order 123 is ready.') }

    it 'returns 4 values when processing from message' do
      result = described_class.new(channel: whatsapp_channel, template_params: nil, message: message).call

      expect(result).to have(4).items
      name, namespace, language, params = result

      expect(name).to eq('order_update')
      expect(namespace).to eq('ns_1')
      expect(language).to eq('en_US')
      expect(params).to include(hash_including(type: 'text', text: 'Jane'))
    end
  end
end
