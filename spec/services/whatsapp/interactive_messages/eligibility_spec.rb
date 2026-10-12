require 'rails_helper'

RSpec.describe Whatsapp::InteractiveMessages::Eligibility do
  subject(:eligibility) { described_class.new(conversation) }

  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: provider, validate_provider_config: false, sync_templates: false)
  end
  let(:provider) { 'whatsapp_cloud' }
  let(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: '+15550000001') }
  let(:contact_inbox) do
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '15550000001')
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }

  before do
    create(:message, :incoming, conversation: conversation, account: conversation.account, inbox: conversation.inbox)
  end

  it 'allows an exact normalized recipient match without returning configured recipients' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      capability = eligibility.capabilities

      expect(capability.dig(:interactive_types, :button)).to include(implemented: true, available: true)
      expect(capability.to_json).not_to include('+15550000001', '+15550000002')
    end
  end

  it 'returns the stable test-recipient restriction for a non-allowlisted recipient' do
    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      expect(eligibility.reason).to eq('test_recipient_not_allowlisted')
      expect { eligibility.ensure_available! }
        .to raise_error(Whatsapp::InteractiveMessages::EligibilityError, 'test_recipient_not_allowlisted')
    end
  end

  it 'returns the stable service-window restriction when the window is closed' do
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect(eligibility.reason).to eq('service_window_closed')
    end
  end

  context 'with a 360dialog inbox' do
    let(:provider) { 'default' }

    it 'reports that the provider is unsupported' do
      with_modified_env described_class::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
        capability = eligibility.capabilities.dig(:interactive_types, :button)

        expect(capability).to include(
          implemented: false,
          available: false,
          unavailable_reason: 'provider_not_supported'
        )
      end
    end
  end
end
