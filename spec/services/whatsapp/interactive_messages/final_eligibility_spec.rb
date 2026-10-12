require 'rails_helper'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Whatsapp::SendOnWhatsappService, '#perform final reply-button eligibility check' do
  let(:whatsapp_channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:contact) { create(:contact, account: whatsapp_channel.account, phone_number: '+15550000001') }
  let(:contact_inbox) do
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '15550000001')
  end
  let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
  let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read) }
  let(:message) do
    create(
      :message,
      conversation: conversation,
      inbox: whatsapp_channel.inbox,
      message_type: :outgoing,
      content: snapshot.dig('body', 'text'),
      content_attributes: { whatsapp_interactive: snapshot }
    )
  end

  before do
    conversation.account.enable_features!(*Whatsapp::InteractiveMessages::Eligibility::TYPE_FEATURES.values)
    create(:message, :incoming, conversation: conversation, inbox: whatsapp_channel.inbox, account: conversation.account)
  end

  it 'fails without provider contact when the type is disabled after message creation' do
    conversation.account.disable_features!('whatsapp_interactive_button')

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'temporarily_disabled')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'fails without provider contact when the service window closes before dispatch' do
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'service_window_closed')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'fails with the same protected-recipient restriction used by capabilities' do
    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      described_class.new(message: message).perform
    end

    expect(message.reload).to have_attributes(status: 'failed', external_error: 'test_recipient_not_allowlisted')
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
