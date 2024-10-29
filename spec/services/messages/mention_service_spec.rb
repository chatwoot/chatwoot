require 'rails_helper'

describe Messages::MentionService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:first_agent) { create(:user, account: account) }
  let!(:second_agent) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let(:builder) { double }

  before do
    create(:inbox_member, user: first_agent, inbox: inbox)
    create(:inbox_member, user: second_agent, inbox: inbox)
    conversation.reload
    allow(NotificationBuilder).to receive(:new).and_return(builder)
    allow(builder).to receive(:perform)
  end

  context 'when message contains mention' do
    it 'creates notifications for inbox member who was mentioned' do
      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: "hi [#{first_agent.name}](mention://user/#{first_agent.id}/#{first_agent.name})",
        private: true
      )

      described_class.new(message: message).perform

      expect(NotificationBuilder).to have_received(:new).with(notification_type: 'conversation_mention',
                                                              user: first_agent,
                                                              account: account,
                                                              primary_actor: message.conversation,
                                                              secondary_actor: message)
    end
  end

  context 'when message contains multiple mentions' do
    let(:message) do
      build(
        :message,
        conversation: conversation,
        account: account,
        content: "hey [#{second_agent.name}](mention://user/#{second_agent.id}/#{second_agent.name})/
                  [#{first_agent.name}](mention://user/#{first_agent.id}/#{first_agent.name}),
                   please look in to this?",
        private: true
      )
    end

    it 'creates notifications for inbox member who was mentioned' do
      described_class.new(message: message).perform

      expect(NotificationBuilder).to have_received(:new).with(notification_type: 'conversation_mention',
                                                              user: second_agent,
                                                              account: account,
                                                              primary_actor: message.conversation,
                                                              secondary_actor: message)
      expect(NotificationBuilder).to have_received(:new).with(notification_type: 'conversation_mention',
                                                              user: first_agent,
                                                              account: account,
                                                              primary_actor: message.conversation,
                                                              secondary_actor: message)
    end

    it 'add the users to the participants list' do
      described_class.new(message: message).perform
      expect(conversation.conversation_participants.map(&:user_id)).to contain_exactly(first_agent.id, second_agent.id)
    end
  end
end
