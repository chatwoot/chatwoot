require 'rails_helper'

RSpec.describe Captain::Tools::ShopifyBaseTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool_class) do
    Class.new(described_class) do
      def perform(*)
        'ok'
      end
    end
  end
  let(:tool) { tool_class.new(assistant) }

  describe '#active?' do
    it 'returns false when captain v2 is disabled' do
      create(:integrations_hook, :shopify, account: account)
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)

      expect(tool.active?).to be false
    end

    it 'returns false when shopify is disconnected' do
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)

      expect(tool.active?).to be false
    end

    it 'returns true when v2 is enabled and shopify is connected' do
      create(:integrations_hook, :shopify, account: account)
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)

      expect(tool.active?).to be true
    end
  end

  describe '#resolve_contact_identity' do
    it 'returns email and phone from state' do
      identity = tool.send(:resolve_contact_identity, { contact: { email: 'john@example.com', phone_number: '+15551234567' } })

      expect(identity).to eq({ email: 'john@example.com', phone_number: '+15551234567' })
    end

    it 'falls back to extracting email from current input when contact identity is missing' do
      identity = tool.send(
        :resolve_contact_identity,
        { contact: {}, captain_v2_trace_current_input: 'Where is my order Russel.winfield@example.com?' }
      )

      expect(identity).to eq({ email: 'Russel.winfield@example.com', phone_number: nil })
    end

    it 'falls back to extracting email from trace history when current input has no identity' do
      trace_input = [
        { role: 'user', content: 'Where is my order Russel.winfield@example.com?' },
        { role: 'assistant', content: 'Please confirm your email' },
        { role: 'user', content: 'Yes' }
      ].to_json

      identity = tool.send(
        :resolve_contact_identity,
        { contact: {}, captain_v2_trace_current_input: 'Yes', captain_v2_trace_input: trace_input }
      )

      expect(identity).to eq({ email: 'Russel.winfield@example.com', phone_number: nil })
    end

    it 'prioritizes explicit identity over contact and inferred identity' do
      state = {
        contact: { email: 'contact@example.com', phone_number: '+15550001111' },
        captain_v2_trace_current_input: 'my alternate is inferred@example.com'
      }
      overrides = { email: 'explicit@example.com', phone_number: '+15551234567' }

      identity = tool.send(:resolve_contact_identity, state, overrides)

      expect(identity).to eq({ email: 'explicit@example.com', phone_number: '+15551234567' })
    end
  end
end
