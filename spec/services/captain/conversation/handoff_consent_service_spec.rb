require 'rails_helper'

RSpec.describe Captain::Conversation::HandoffConsentService do
  subject(:service) { described_class.new(conversation: conversation, assistant: assistant) }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: create(:inbox, account: account)) }

  def add_message(message_type, content)
    conversation.messages.create!(
      message_type: message_type,
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      content: content
    )
  end

  describe '#consented_to_human_help?' do
    it 'is true when the customer explicitly asks for a human' do
      add_message(:incoming, 'Can I talk to a real human please?')

      expect(service.consented_to_human_help?).to be(true)
    end

    it 'is true when the customer asks to be escalated' do
      add_message(:incoming, 'Please escalate this to a manager')

      expect(service.consented_to_human_help?).to be(true)
    end

    it 'is true when the customer accepts a prior offer to speak with a human' do
      add_message(:incoming, 'what is kira')
      add_message(:outgoing, 'I could not answer that. Would you like to speak with a human agent?')
      add_message(:incoming, 'yes please')

      expect(service.consented_to_human_help?).to be(true)
    end

    it 'is false when the customer has not asked for or accepted a human' do
      add_message(:incoming, 'what is kira')

      expect(service.consented_to_human_help?).to be(false)
    end

    it 'is false when there is an offer but the customer has not replied' do
      add_message(:incoming, 'what is kira')
      add_message(:outgoing, 'Would you like to speak with a human agent?')

      expect(service.consented_to_human_help?).to be(false)
    end

    it 'is false when there is no offer and no request' do
      add_message(:incoming, 'how do I reset my password')

      expect(service.consented_to_human_help?).to be(false)
    end
  end
end
