require 'rails_helper'

describe Whatsapp::TemplateProcessorService do
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
