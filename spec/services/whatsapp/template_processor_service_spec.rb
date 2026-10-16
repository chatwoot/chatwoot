require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
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

  context 'with a static button before a dynamic button' do
    let(:template) do
      {
        'name' => 'offer', 'language' => 'en_US', 'status' => 'APPROVED',
        'components' => [
          { 'type' => 'BODY', 'text' => 'Your offer' },
          { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'QUICK_REPLY', 'text' => 'Thanks' }, { 'type' => 'COPY_CODE' }] }
        ]
      }
    end
    let(:template_params) do
      {
        'name' => 'offer', 'language' => 'en_US',
        'processed_params' => { 'buttons' => [nil, { 'type' => 'copy_code', 'parameter' => 'WELCOME' }] }
      }
    end

    it 'preserves the dynamic button index through normalization and payload generation' do
      expect(processed_components).to eq([
                                           { type: 'button', sub_type: 'copy_code', index: 1,
                                             parameters: [{ type: 'coupon_code', coupon_code: 'WELCOME' }] }
                                         ])
    end
  end

  context 'with FLOW buttons' do
    let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let(:conversation) { create(:conversation, inbox: channel.inbox) }
    let(:message) { create(:message, conversation: conversation) }

    let(:flow_template) do
      {
        'name' => 'book_a_demo',
        'language' => 'es_CO',
        'status' => 'approved',
        'components' => [
          { 'type' => 'BODY', 'text' => 'Hi {{1}}, book your demo here:' },
          { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'FLOW', 'text' => 'Book demo' }] }
        ]
      }
    end

    let(:plain_template) do
      {
        'name' => 'plain_hello',
        'language' => 'en',
        'status' => 'approved',
        'components' => [{ 'type' => 'BODY', 'text' => 'Hello {{1}}!' }]
      }
    end

    def process(template, template_params)
      allow(channel).to receive(:message_templates).and_return([template])
      described_class.new(channel: channel, template_params: template_params, message: message).call
    end

    describe 'templates with FLOW buttons' do
      it 'appends the flow button component with a flow_token' do
        _name, _namespace, _lang, components = process(
          flow_template,
          { 'name' => 'book_a_demo', 'language' => 'es_CO', 'processed_params' => { 'body' => { '1' => 'Ana' } } }
        )

        flow_component = components.find { |c| c[:type] == 'button' && c[:sub_type] == 'flow' }
        expect(flow_component).to be_present
        expect(flow_component[:index]).to eq(0)
        action = flow_component[:parameters].first
        expect(action[:type]).to eq('action')
        expect(action[:action][:flow_token]).to include("chatwoot_#{conversation.display_id}_")
      end

      it 'keeps a single flow component and preserves a caller-supplied token' do
        _name, _namespace, _lang, components = process(
          flow_template,
          {
            'name' => 'book_a_demo', 'language' => 'es_CO',
            'processed_params' => {
              'body' => { '1' => 'Ana' },
              'buttons' => [{ 'type' => 'flow', 'parameter' => 'custom_token' }]
            }
          }
        )

        flow_components = components.select { |c| c[:type] == 'button' && c[:index] == 0 }
        expect(flow_components.size).to eq(1)
        # The caller token must round-trip as an action/flow_token payload,
        # not a text parameter (otherwise Meta rejects it with 131009).
        parameter = flow_components.first[:parameters].first
        expect(parameter[:type]).to eq('action')
        expect(parameter[:action][:flow_token]).to eq('custom_token')
      end
    end

    describe 'templates without FLOW buttons' do
      it 'does not append any flow component' do
        _name, _namespace, _lang, components = process(
          plain_template,
          { 'name' => 'plain_hello', 'language' => 'en', 'processed_params' => { 'body' => { '1' => 'Ana' } } }
        )

        expect(components.none? { |c| c[:sub_type] == 'flow' }).to be(true)
      end
    end
  end
end
