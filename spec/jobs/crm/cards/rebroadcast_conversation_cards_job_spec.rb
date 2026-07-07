require 'rails_helper'

RSpec.describe Crm::Cards::RebroadcastConversationCardsJob, type: :job do
  it 'broadcasts CRM_CARD_UPDATED for every card linked to the conversation' do
    account, user = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'CTWA Lead', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    linked_cards = Array.new(2) do |index|
      account.crm_cards.create!(pipeline: pipeline, stage: stage, title: "Card #{index}", status: :open).tap do |card|
        Crm::CardConversation.create!(account: account, card: card, conversation: conversation)
      end
    end
    unrelated_card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Sem vínculo', status: :open)

    allow(Crm::Cards::Broadcaster).to receive(:broadcast)

    described_class.perform_now(conversation.id)

    linked_cards.each do |card|
      expect(Crm::Cards::Broadcaster).to have_received(:broadcast).with(card, Events::Types::CRM_CARD_UPDATED)
    end
    expect(Crm::Cards::Broadcaster).not_to have_received(:broadcast).with(unrelated_card, anything)
  end

  it 'broadcasts for a legacy card that references the conversation without a link row' do
    account, user = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Legacy Lead', phone_number: '+5511912345678')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    # Pre-link-table era: crm_cards.conversation_id set, no crm_card_conversations row.
    legacy_card = account.crm_cards.create!(
      pipeline: pipeline, stage: stage, title: 'Card legado', status: :open, conversation_id: conversation.id
    )
    Crm::CardConversation.where(card: legacy_card).delete_all

    allow(Crm::Cards::Broadcaster).to receive(:broadcast)

    described_class.perform_now(conversation.id)

    expect(Crm::Cards::Broadcaster).to have_received(:broadcast).with(legacy_card, Events::Types::CRM_CARD_UPDATED)
  end

  it 'does nothing when the conversation has no linked cards' do
    allow(Crm::Cards::Broadcaster).to receive(:broadcast)

    described_class.perform_now(-1)

    expect(Crm::Cards::Broadcaster).not_to have_received(:broadcast)
  end
end
