require 'rails_helper'

# The company half of the contact clock. `update_columns` skips the callback that rolls a
# contact's activity up to its company, which is deliberate everywhere else -- the import
# writes clocks without firing the machinery around them -- so the roll-up has to be asked for.
describe Import::HistorySettlement do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:company) { create(:company, account: account, domain: 'empresa.example.com') }
  let(:contact) { create(:contact, account: account, company: company) }
  let(:conversation) do
    contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end

  let(:settler) do
    Class.new do
      include Import::HistorySettlement
      attr_reader :opened

      def initialize = @opened = Set.new
      def announcing(&) = yield
      def run(rows) = settle(rows, [])
    end
  end

  def incoming(at)
    Import::SilentWrite.wrap do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :incoming, sender: contact, created_at: at,
                       content_attributes: { imported: true })
    end
  end

  it 'rolls the imported clock up to the company' do
    settler.new.run([incoming(Time.zone.parse('2023-05-01 10:00'))])
    expect(company.reload.last_activity_at).to eq(Time.zone.parse('2023-05-01 10:00'))
  end

  # A company somebody is talking to today keeps its clock; that is the company's own rule
  # and history has no business overriding it.
  it 'never drags a company backwards' do
    company.update!(last_activity_at: Time.zone.parse('2026-01-01 09:00'))
    settler.new.run([incoming(Time.zone.parse('2023-05-01 10:00'))])
    expect(company.reload.last_activity_at).to eq(Time.zone.parse('2026-01-01 09:00'))
  end

  # The clock and the roll-up are two writes with nothing holding them together. A run that
  # stops between them leaves the contact stamped and the company stale, and the retry
  # finds a contact already reading the batch's newest date: if that skipped the pair, the
  # company would never be asked for again.
  it 'still rolls the company up when the contact clock already reads what it would write' do
    at = Time.zone.parse('2023-05-01 10:00')
    row = incoming(at)
    contact.update_columns(last_activity_at: at) # rubocop:disable Rails/SkipsModelValidations
    expect(company.reload.last_activity_at).to be_nil

    settler.new.run([row])
    expect(company.reload.last_activity_at).to eq(at)
  end

  it 'leaves a contact with no company alone rather than raising' do
    contact.update!(company: nil)
    expect { settler.new.run([incoming(Time.zone.parse('2023-05-01 10:00'))]) }.not_to raise_error
  end
end
