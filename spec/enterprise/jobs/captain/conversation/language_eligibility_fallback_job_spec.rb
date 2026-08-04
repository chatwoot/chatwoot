require 'rails_helper'

RSpec.describe Captain::Conversation::LanguageEligibilityFallbackJob do
  let(:conversation) do
    create(:conversation, status: :pending,
                          additional_attributes: { Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY => true })
  end
  let(:message) { create(:message, conversation: conversation, message_type: :incoming) }

  it 'routes a conversation to humans when language detection did not finish' do
    described_class.perform_now(conversation, message)

    expect(conversation.reload).to be_open
    expect(conversation.additional_attributes).not_to have_key(Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY)
  end

  it 'does nothing after language eligibility has completed' do
    conversation.update!(additional_attributes: {})

    expect { described_class.perform_now(conversation, message) }.not_to(change { conversation.reload.status })
  end
end
