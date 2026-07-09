require 'rails_helper'

RSpec.describe Crm::Cards::Creator do
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

  def perform(conversation:, params: {})
    described_class.new(
      account: account, user: admin, conversation: conversation,
      params: { pipeline_id: pipeline.id, stage_id: stage.id, title: 'Card' }.merge(params)
    ).perform
  end

  # Reason: hydrate_from_conversation must derive last_message_at from the last
  # REAL message (Message.chat), never from conversation.last_activity_at, which
  # any system activity bumps.
  it 'sets last_message_at from the conversation last real message' do
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Primeira')
    real_message = create_message(conversation: conversation, content: 'Segunda')

    card = perform(conversation: conversation)

    expect(card.last_message_at.to_i).to eq(real_message.created_at.to_i)
  end

  # Reason: activity and private messages must never count as "real" activity
  # for the CRM Kanban inactivity filter.
  it 'ignores activity and private messages when deriving last_message_at' do
    conversation = create_conversation
    real_message = create_message(conversation: conversation, content: 'Mensagem real')
    create_message(conversation: conversation, content: 'Nota privada', private: true)
    create_message(conversation: conversation, content: 'Assignee mudou', message_type: :activity)

    card = perform(conversation: conversation)

    expect(card.last_message_at.to_i).to eq(real_message.created_at.to_i)
  end

  # Reason: NULL is the intentional, documented outcome when the conversation has
  # no real message yet — the "Inatividade" filter treats NULL as stale.
  it 'leaves last_message_at nil when the conversation has no real message' do
    conversation = create_conversation
    create_message(conversation: conversation, content: 'Assignee mudou', message_type: :activity)

    card = perform(conversation: conversation)

    expect(card.last_message_at).to be_nil
  end
end
