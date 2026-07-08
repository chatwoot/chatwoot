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

  it 'returns nil (no follow-up) when the timezone is unresolvable' do
    account, user = create_account_and_user
    card = setup_card(account: account, user: user)
    local_date = (3.days.from_now).strftime('%Y-%m-%d')

    expect(described_class.new(card: card, callback: callback_at(local_date)).perform).to be_nil
  end
end
