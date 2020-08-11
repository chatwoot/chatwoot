# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentNotifications::ConversationNotificationsMailer, type: :mailer do
  let(:class_instance) { described_class.new }
  let(:agent) { create(:user, email: 'agent1@example.com') }
  let(:conversation) { create(:conversation, assignee: agent) }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
  end

  describe 'conversation_creation' do
    let(:mail) { described_class.conversation_creation(conversation, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, A new conversation [ID - #{conversation
        .display_id}] has been created in #{conversation.inbox&.name}.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end

  describe 'conversation_assignment' do
    let(:mail) { described_class.conversation_assignment(conversation, agent).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("#{agent.available_name}, A new conversation [ID - #{conversation.display_id}] has been assigned to you.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([agent.email])
    end
  end
end
