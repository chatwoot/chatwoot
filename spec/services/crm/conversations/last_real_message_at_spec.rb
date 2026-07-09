require 'rails_helper'

RSpec.describe Crm::Conversations::LastRealMessageAt do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create_crm_inbox(account: account, members: [admin]) }

  def create_conversation
    contact = account.contacts.create!(name: "Lead #{SecureRandom.hex(3)}", phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    create_crm_conversation(account: account, inbox: inbox, contact: contact)
  end

  def create_message(conversation:, content: 'Olá', private: false, message_type: :incoming)
    conversation.messages.create!(
      account: conversation.account, inbox: conversation.inbox, sender: conversation.contact,
      content: content, message_type: message_type, private: private
    )
  end

  it 'returns the created_at of the most recent chat message' do
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Primeira')
    last_message = create_message(conversation: conversation, content: 'Segunda')

    expect(described_class.for(conversation).to_i).to eq(last_message.created_at.to_i)
  end

  it 'ignores private and activity messages' do
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Nota privada', private: true)
    create_message(conversation: conversation, content: 'Assignee mudou', message_type: :activity)

    expect(described_class.for(conversation)).to be_nil
  end

  it 'returns nil when the conversation has no message at all' do
    conversation = create_conversation

    expect(described_class.for(conversation)).to be_nil
  end

  it 'returns nil when the conversation is blank' do
    expect(described_class.for(nil)).to be_nil
  end
end
