# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentNotifications::ConversationNotificationsMailer, type: :mailer do
  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
  let(:conversation) { create(:conversation, assignee: agent, account: account) }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
  end

  describe 'conversation_creation' do
    let(:mail) { described_class.with(account: account).conversation_creation(conversation, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, A new conversation [ID - #{conversation
        .display_id}] has been created in #{conversation.inbox&.name}.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'conversation_assignment' do
    let(:mail) { described_class.with(account: account).conversation_assignment(conversation, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, A new conversation [ID - #{conversation.display_id}] has been assigned to you.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'conversation_mention' do
    let(:message) { create(:message, conversation: conversation, account: account) }
    let(:mail) { described_class.with(account: account).conversation_mention(message, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, You have been mentioned in conversation [ID - #{conversation.display_id}]")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'assigned_conversation_new_message' do
    let(:message) { create(:message, conversation: conversation, account: account) }
    let(:mail) { described_class.with(account: account).assigned_conversation_new_message(message, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, New message in your assigned conversation [ID - #{message.conversation.display_id}].")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end

    it 'will not send email if agent is online' do
      ::OnlineStatusTracker.update_presence(conversation.account.id, 'User', agent.id)
      expect(mail).to eq nil
    end
  end
end
