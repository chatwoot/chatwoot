require 'rails_helper'

RSpec.describe Crm::Ai::SuggestMeetingTimeService do
  it 'returns [] when the timezone is unresolvable (no explicit, contact or account tz)' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: user, title: 'Lead'
    )

    result = described_class.new(card: card, inbox: inbox, date: Date.current).perform

    expect(result).to eq([])
  end
end
