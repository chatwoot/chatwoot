require 'rails_helper'

RSpec.describe Crm::FollowUps::AutoFollowupTouchBuilder do
  def setup_card(account:, user:, contact_tz: nil, owner: :unset, assignee: :unset)
    owner = user if owner == :unset
    assignee = user if assignee == :unset
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    contact.update!(additional_attributes: { 'timezone' => contact_tz }) if contact_tz
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: assignee)
    create_incoming_message(conversation: conversation)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: owner, title: 'Lead'
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

  # Reason (CHANGED from fail-closed): with no explicit tz, no contact tz and no
  # account reporting_timezone, the cadence touch must still be created anchored to
  # the São Paulo default instead of raising Unresolvable — an unresolved tz can no
  # longer silently drop touch #1.
  it 'defaults the stored timezone to America/Sao_Paulo when nothing resolves' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    card = setup_card(account: account, user: user)

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current).perform

    expect(follow_up).to be_persisted
    expect(follow_up.timezone).to eq('America/Sao_Paulo')
  end

  # Reason: a single-timezone country on the contact pins the cadence tz over the
  # account default (foreigner correctness through the AI follow-up path).
  it 'derives a single-timezone country from the contact when no tz is passed (FR -> Europe/Paris)' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    card = setup_card(account: account, user: user)
    # The resolver reads the ISO code from additional_attributes['country_code']
    # (geocoder-populated), NOT the contact.country_code column (which holds the
    # country NAME). Set the ISO code the way the geocoder does.
    card.contact.update!(additional_attributes: { 'country_code' => 'FR' })

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current).perform

    expect(follow_up.timezone).to eq('Europe/Paris')
  end

  # Reason (PR1): a card with no owner and no conversation assignee (AI-only /
  # unassigned) must still produce a touch with a resolved sender, otherwise
  # MessageSender returns 'sender_required' and the whole cadence dies 'send_failed'.
  # The sender falls back to the account administrator.
  it 'falls back to the account administrator when the card has no owner or assignee' do
    account, admin = create_account_and_user
    card = setup_card(account: account, user: admin, owner: nil, assignee: nil)

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current).perform

    expect(follow_up.created_by).to eq(admin)
    expect(follow_up.assignee).to eq(admin)
  end

  # Control: when the card has an owner, that owner stays the sender (owner wins
  # over the admin fallback) — the happy path is unchanged.
  it 'keeps the card owner as the sender when the card has an owner' do
    account, admin = create_account_and_user
    owner, = create_crm_agent(account: account)
    card = setup_card(account: account, user: admin, owner: owner, assignee: nil)

    follow_up = described_class.new(card: card, touch: 1, due_at: Time.current).perform

    expect(follow_up.created_by).to eq(owner)
    expect(follow_up.assignee).to eq(owner)
  end
end
