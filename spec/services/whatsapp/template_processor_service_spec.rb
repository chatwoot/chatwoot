require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
  describe 'flow buttons' do
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

  describe 'template parameters' do
    subject(:processed_components) do
      described_class.new(channel: channel, template_params: template_params).call.last
    end

    let(:channel) { instance_double(Channel::Whatsapp, message_templates: [template]) }
    let(:template_params) do
      {
        'name' => template['name'],
        'language' => template['language'],
        'processed_params' => { 'header' => header_params }
      }
    end

    context 'with a positional text header' do
      let(:template) do
        {
          'name' => 'positional_header',
          'language' => 'en_US',
          'status' => 'APPROVED',
          'parameter_format' => 'POSITIONAL',
          'components' => [{ 'type' => 'HEADER', 'format' => 'TEXT', 'text' => 'Welcome {{1}}' }]
        }
      end
      let(:header_params) { { '1' => 'Jane' } }

      it 'builds a positional text parameter' do
        expect(processed_components).to eq([
                                             {
                                               type: 'header',
                                               parameters: [{ type: 'text', text: 'Jane' }]
                                             }
                                           ])
      end
    end

    context 'with a named text header' do
      let(:template) do
        {
          'name' => 'named_header',
          'language' => 'en_US',
          'status' => 'APPROVED',
          'parameter_format' => 'NAMED',
          'components' => [{ 'type' => 'HEADER', 'format' => 'TEXT', 'text' => "Welcome {{#{parameter_name}}}" }]
        }
      end
      let(:header_params) { { parameter_name => 'Jane' } }

      %w[customer_name media_type media_name].each do |name|
        context "when the parameter is #{name}" do
          let(:parameter_name) { name }

          it 'preserves the parameter name' do
            expect(processed_components).to eq([
                                                 {
                                                   type: 'header',
                                                   parameters: [{ type: 'text', parameter_name: parameter_name, text: 'Jane' }]
                                                 }
                                               ])
          end
        end
      end
    end

    context 'with positional body parameters' do
      let(:template) do
        {
          'name' => 'positional_body',
          'language' => 'en_US',
          'status' => 'APPROVED',
          'parameter_format' => 'POSITIONAL',
          'components' => [{ 'type' => 'BODY', 'text' => '{{1}} / {{2}}' }]
        }
      end
      let(:template_params) do
        {
          'name' => template['name'],
          'language' => template['language'],
          'processed_params' => {
            'body' => {
              '2' => 'Bob',
              '1' => 'Alice'
            }
          }
        }
      end

      it 'orders parameters by their positional key' do
        expect(processed_components).to eq([
                                             {
                                               type: 'body',
                                               parameters: [
                                                 { type: 'text', text: 'Alice' },
                                                 { type: 'text', text: 'Bob' }
                                               ]
                                             }
                                           ])
      end
    end

    context 'with a media header' do
      let(:template) do
        {
          'name' => 'document_header',
          'language' => 'en_US',
          'status' => 'APPROVED',
          'parameter_format' => 'POSITIONAL',
          'components' => [{ 'type' => 'HEADER', 'format' => 'DOCUMENT' }]
        }
      end
      let(:header_params) do
        {
          'media_url' => 'https://example.com/report.pdf',
          'media_type' => 'document',
          'media_name' => 'report.pdf'
        }
      end

      it 'uses media metadata to build the attachment parameter' do
        expect(processed_components).to eq([
                                             {
                                               type: 'header',
                                               parameters: [
                                                 {
                                                   type: 'document',
                                                   document: {
                                                     link: 'https://example.com/report.pdf',
                                                     filename: 'report.pdf'
                                                   }
                                                 }
                                               ]
                                             }
                                           ])
      end
    end
  end
end
