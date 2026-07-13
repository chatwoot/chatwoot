require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  let(:channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let(:message) { nil }

  let(:flow_template) do
    {
      'name' => 'pedido_datos_envio',
      'language' => 'es',
      'status' => 'APPROVED',
      'components' => [
        {
          'type' => 'BODY',
          'text' => "Banco Pichincha\nCuenta CORRIENTE: 2100352260"
        },
        {
          'type' => 'BUTTONS',
          'buttons' => [
            {
              'type' => 'FLOW',
              'text' => 'Completar formulario',
              'flow_id' => '123456789'
            }
          ]
        }
      ]
    }
  end

  before do
    channel.update!(message_templates: [flow_template])
  end

  describe '#call' do
    it 'includes Meta flow button action when template has a FLOW button' do
      template_params = {
        'name' => 'pedido_datos_envio',
        'language' => 'es',
        'processed_params' => {}
      }

      name, _namespace, language, components = described_class.new(
        channel: channel,
        template_params: template_params,
        message: message
      ).call

      expect(name).to eq('pedido_datos_envio')
      expect(language).to eq('es')
      expect(components).to contain_exactly(
        {
          type: 'button',
          sub_type: 'flow',
          index: '0',
          parameters: [
            {
              type: 'action',
              action: { flow_token: 'unused' }
            }
          ]
        }
      )
    end

    it 'uses message-scoped flow_token when message is present' do
      conversation = create(:conversation, inbox: channel.inbox)
      message = create(:message, conversation: conversation, message_type: :outgoing)

      template_params = {
        'name' => 'pedido_datos_envio',
        'language' => 'es',
        'processed_params' => {}
      }

      _name, _namespace, _language, components = described_class.new(
        channel: channel,
        template_params: template_params,
        message: message
      ).call

      expect(components.first[:parameters].first[:action][:flow_token])
        .to eq("cw_#{conversation.id}_#{message.id}")
    end

    it 'does not send empty flow_action_data' do
      template_params = {
        'name' => 'pedido_datos_envio',
        'language' => 'es',
        'processed_params' => {
          'buttons' => [
            { 'type' => 'flow', 'flow_action_data' => {} }
          ]
        }
      }

      _name, _namespace, _language, components = described_class.new(
        channel: channel,
        template_params: template_params
      ).call

      expect(components.first[:parameters].first[:action]).not_to have_key(:flow_action_data)
    end

    it 'includes non-empty flow_action_data when provided' do
      template_params = {
        'name' => 'pedido_datos_envio',
        'language' => 'es',
        'processed_params' => {
          'buttons' => [
            {
              'type' => 'flow',
              'flow_token' => 'custom_token',
              'flow_action_data' => { 'order_id' => '42' }
            }
          ]
        }
      }

      _name, _namespace, _language, components = described_class.new(
        channel: channel,
        template_params: template_params
      ).call

      expect(components.first[:parameters].first[:action]).to eq(
        flow_token: 'custom_token',
        flow_action_data: { 'order_id' => '42' }
      )
    end
  end
end
