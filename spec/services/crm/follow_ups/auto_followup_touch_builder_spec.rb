require 'rails_helper'

RSpec.describe Crm::FollowUps::AutoFollowupTouchBuilder do
  def setup_card(account:, user:, contact_tz: nil)
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    contact.update!(additional_attributes: { 'timezone' => contact_tz }) if contact_tz
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    create_incoming_message(conversation: conversation)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: user, title: 'Lead'
    )
  end

  it 'stores the explicit timezone passed in' do
    account, user = create_account_and_user
    card = setup_card(account: account, user: user)

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current, timezone: 'America/Sao_Paulo').perform

    expect(follow_up.timezone).to eq('America/Sao_Paulo')
  end

  it 'resolves the timezone from the card when none is passed' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: 'America/Sao_Paulo')
    card = setup_card(account: account, user: user)

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current).perform

    expect(follow_up.timezone).to eq('America/Sao_Paulo')
  end

  it 'raises when no timezone can be resolved' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    card = setup_card(account: account, user: user)

    expect do
      described_class.new(card: card, touch: 1, due_at: Time.current).perform
    end.to raise_error(Crm::Timezone::Resolver::Unresolvable)
  end
end
