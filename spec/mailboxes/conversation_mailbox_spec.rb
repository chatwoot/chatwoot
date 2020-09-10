require 'rails_helper'

RSpec.describe ConversationMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  describe 'add mail as reply in a conversation' do
    let(:account) { create(:account) }
    let(:agent) { create(:user, email: 'agent1@example.com', account: account) }
    let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }
    let(:conversation) { create(:conversation, assignee: agent, inbox: create(:inbox, account: account, greeting_enabled: false), account: account) }
    let(:described_subject) { described_class.receive reply_mail }
    let(:serialized_attributes) { %w[text_content html_content number_of_attachments subject date to from in_reply_to cc bcc message_id] }

    before do
      # this UUID is hardcoded in the reply.eml, that's why we are updating this
      conversation.uuid = '6bdc3f4d-0bec-4515-a284-5d916fdde489'
      conversation.save

      described_subject
    end

    it 'add the mail content as new message on the conversation' do
      expect(conversation.messages.last.content).to eq("Let's talk about these images:")
    end

    it 'add the attachments' do
      expect(conversation.messages.last.attachments.count).to eq(2)
    end

    it 'have proper content_attributes with details of email' do
      expect(conversation.messages.last.content_attributes[:email].keys).to eq(serialized_attributes)
    end

    it 'set proper content_type' do
      expect(conversation.messages.last.content_type).to eq('incoming_email')
    end
  end
end
