require 'rails_helper'

RSpec.describe Crm::Cards::ConversationLinker do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create_crm_inbox(account: account, members: [admin]) }
  let(:pipeline_and_stage) { create_crm_pipeline(account: account, user: admin) }
  let(:pipeline) { pipeline_and_stage.first }
  let(:stage) { pipeline_and_stage.last }

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

  def create_standalone_card
    account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Card standalone')
  end

  # Reason: linking a conversation as primary must derive last_message_at from
  # the last REAL message of that conversation, never from conversation.
  # last_activity_at, which any system activity (assignee/team changes,
  # activity messages) bumps.
  it 'sets last_message_at from the conversation last real message when linking as primary' do
    card = create_standalone_card
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Primeira')
    real_message = create_message(conversation: conversation, content: 'Segunda')

    described_class.new(card: card, conversation: conversation, actor: admin, primary: true).link

    expect(card.reload.last_message_at.to_i).to eq(real_message.created_at.to_i)
  end

  # Reason: activity and private messages must never count as "real" activity
  # for the CRM Kanban inactivity filter, even right after linking.
  it 'ignores activity and private messages when deriving last_message_at' do
    card = create_standalone_card
    conversation = create_conversation
    real_message = create_message(conversation: conversation, content: 'Mensagem real')
    create_message(conversation: conversation, content: 'Nota privada', private: true)
    create_message(conversation: conversation, content: 'Assignee mudou', message_type: :activity)

    described_class.new(card: card, conversation: conversation, actor: admin, primary: true).link

    expect(card.reload.last_message_at.to_i).to eq(real_message.created_at.to_i)
  end

  # Reason: NULL is the intentional, documented outcome when the conversation
  # has no real message yet — the "Inatividade" filter treats NULL as stale.
  it 'sets last_message_at to nil when the conversation has no real message' do
    card = create_standalone_card
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Assignee mudou', message_type: :activity)

    described_class.new(card: card, conversation: conversation, actor: admin, primary: true).link

    expect(card.reload.last_message_at).to be_nil
  end
end
