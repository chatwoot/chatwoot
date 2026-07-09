require 'rails_helper'

RSpec.describe Crm::FollowUps::CallbackScheduler do
  def setup_card(account:, user:, contact_tz: nil, account_tz: nil)
    account.update!(reporting_timezone: account_tz) if account_tz
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    contact.update!(additional_attributes: { 'timezone' => contact_tz }) if contact_tz
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: user, title: 'Lead'
    )
  end

  # A card wired for an auto_send_message callback: WhatsApp-capable inbox +
  # pipeline callback_mode 'message'. owner/assignee are overridable so we can
  # exercise the AI-only / unassigned (no owner, no assignee) sender fallback.
  def setup_message_card(account:, user:, owner: :unset, assignee: :unset)
    owner = user if owner == :unset
    assignee = user if assignee == :unset
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: assignee)
    create_incoming_message(conversation: conversation)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    pipeline.update!(metadata: { 'ai' => { 'callback_mode' => 'message' } })
    account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: owner, title: 'Lead'
    )
  end

  def callback_at(local_date)
    {
      detected: true,
      confidence: 0.9,
      requested_at: "#{local_date}T08:00",
      requested_at_text: 'na próxima terça às 8h'
    }
  end

  it 'anchors 08:00 local (America/Sao_Paulo) to 11:00 UTC (not 08:00)' do
    account, user = create_account_and_user
    card = setup_card(account: account, user: user, contact_tz: 'America/Sao_Paulo')
    local_date = (3.days.from_now).strftime('%Y-%m-%d')

    follow_up = described_class.new(card: card, callback: callback_at(local_date)).perform

    expect(follow_up).to be_present
    expect(follow_up.due_at.utc.hour).to eq(11)
  end

  # Reason (CHANGED from fail-closed): with NO contact tz and NO account
  # reporting_timezone the callback must still schedule, anchoring the 08:00 local
  # request to the São Paulo default (11:00 UTC) instead of returning nil. A
  # missing tz can no longer silently swallow a detected callback.
  it 'defaults to America/Sao_Paulo and still schedules (08:00 local => 11:00 UTC)' do
    account, user = create_account_and_user
    card = setup_card(account: account, user: user)
    local_date = (3.days.from_now).strftime('%Y-%m-%d')

    follow_up = described_class.new(card: card, callback: callback_at(local_date)).perform

    expect(follow_up).to be_present
    expect(follow_up.timezone).to eq('America/Sao_Paulo')
    expect(follow_up.due_at.utc.hour).to eq(11)
  end

  # Reason (PR1): an auto_send_message callback on a card with no owner and no
  # conversation assignee (AI-only / unassigned) must still carry a sender,
  # otherwise MessageSender returns 'sender_required' and the send dies
  # 'send_failed'. The sender falls back to the account administrator.
  it 'falls back to the account administrator as sender on the auto_send_message callback' do
    account, admin = create_account_and_user
    card = setup_message_card(account: account, user: admin, owner: nil, assignee: nil)
    local_date = (3.days.from_now).strftime('%Y-%m-%d')

    follow_up = described_class.new(card: card, callback: callback_at(local_date)).perform

    expect(follow_up).to be_auto_send_message
    expect(follow_up.created_by).to eq(admin)
    expect(follow_up.assignee).to eq(admin)
  end

  # Control: when the card has an owner, that owner stays the sender (owner wins
  # over the admin fallback) — the happy path is unchanged.
  it 'keeps the card owner as sender on the auto_send_message callback when present' do
    account, admin = create_account_and_user
    owner, = create_crm_agent(account: account)
    card = setup_message_card(account: account, user: admin, owner: owner, assignee: nil)
    local_date = (3.days.from_now).strftime('%Y-%m-%d')

    follow_up = described_class.new(card: card, callback: callback_at(local_date)).perform

    expect(follow_up).to be_auto_send_message
    expect(follow_up.created_by).to eq(owner)
    expect(follow_up.assignee).to eq(owner)
  end
end
