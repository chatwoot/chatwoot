require 'rails_helper'

RSpec.describe ScheduledMessages::TriggerScheduledMessagesJob, type: :job do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  describe '#perform' do
    it 'enqueues jobs for due scheduled messages only' do
      due_same_minute = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author,
                                                   scheduled_at: 1.minute.from_now)
      overdue = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author,
                                           scheduled_at: 2.minutes.from_now)
      future = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author,
                                          scheduled_at: 5.minutes.from_now)
      draft = create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author,
                                         scheduled_at: 3.minutes.from_now, status: :draft)

      travel_to(3.minutes.from_now) do
        clear_enqueued_jobs
        described_class.new.perform

        enqueued_ids = enqueued_jobs
                       .select { |job| job[:job] == ScheduledMessages::SendScheduledMessageJob }
                       .map { |job| job[:args].first }

        expect(enqueued_ids).to contain_exactly(due_same_minute.id, overdue.id)
        expect(enqueued_ids).not_to include(future.id)
        expect(enqueued_ids).not_to include(draft.id)
      end
    end
  end
end
