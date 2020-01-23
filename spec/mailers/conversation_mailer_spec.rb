# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationMailer, type: :mailer do
  describe 'new_message' do
    let(:agent) { create(:user, email: 'agent1@example.com') }
    let(:conversation) { create(:conversation, assignee: agent) }
    let(:message) { create(:message, conversation: conversation) }
    let(:mail) { described_class.new_message(message.conversation, Time.zone.now).deliver_now }
    let(:class_instance) { described_class.new }

    before do
      allow(described_class).to receive(:new).and_return(class_instance)
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    it 'renders the subject' do
      expect(mail.subject).to eq("[##{message.conversation.display_id}] #{message.content.truncate(30)}")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([message&.conversation&.contact&.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq([message&.conversation&.assignee&.email])
    end
  end
end
