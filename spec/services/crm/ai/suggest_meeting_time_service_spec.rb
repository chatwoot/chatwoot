require 'rails_helper'

RSpec.describe Crm::Ai::SuggestMeetingTimeService do
  def setup_card(account:, user:)
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, owner: user, title: 'Lead'
    )
    [card, inbox]
  end

  # Isolate the timezone behaviour: force an empty busy calendar so the free grid
  # is deterministic and no provider call happens. With no AI credential the
  # service degrades to the raw free slots (reason: nil).
  before do
    availability = instance_double(Crm::Meetings::AvailabilityService, busy_intervals: [])
    allow(Crm::Meetings::AvailabilityService).to receive(:new).and_return(availability)
  end

  # Reason (CHANGED from returning []): with NO explicit tz, NO contact tz and NO
  # account reporting_timezone the service must still suggest times, anchored to
  # the São Paulo default. The first business-hours slot is 08:00 local = 11:00
  # UTC, proving it did NOT collapse to an empty result or to a UTC wall time.
  it 'defaults to America/Sao_Paulo and suggests slots anchored to local business hours' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    card, inbox = setup_card(account: account, user: user)

    result = described_class.new(card: card, inbox: inbox, date: Date.new(2026, 7, 8)).perform

    expect(result).not_to be_empty
    expect(result.size).to be <= described_class::MAX_SUGGESTIONS
    first_utc = Time.iso8601(result.first[:starts_at]).utc
    expect(first_utc.hour).to eq(11)
  end

  # Reason: a single-timezone country on the contact pins the suggestion grid to
  # the lead's local business hours (foreigner correctness). 08:00 Europe/Paris in
  # July (CEST, UTC+2) is 06:00 UTC.
  it 'derives a single-timezone country from the contact (FR -> Europe/Paris, 08:00 local => 06:00 UTC)' do
    account, user = create_account_and_user
    account.update!(reporting_timezone: nil)
    card, inbox = setup_card(account: account, user: user)
    # The resolver reads the ISO code from additional_attributes['country_code']
    # (geocoder-populated), NOT the contact.country_code column (which holds the
    # country NAME). Set the ISO code the way the geocoder does.
    card.contact.update!(additional_attributes: { 'country_code' => 'FR' })

    result = described_class.new(card: card, inbox: inbox, date: Date.new(2026, 7, 8)).perform

    expect(result).not_to be_empty
    first_utc = Time.iso8601(result.first[:starts_at]).utc
    expect(first_utc.hour).to eq(6)
  end
end
