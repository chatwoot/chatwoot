require 'rails_helper'

RSpec.describe DeleteObjectJob, type: :job do
  describe '#perform' do
    context 'when object is heavy (Inbox)' do
      let!(:account) { create(:account) }
      let!(:inbox) { create(:inbox, account: account) }

      before do
        create_list(:conversation, 3, account: account, inbox: inbox)
        ReportingEvent.create!(account: account, inbox: inbox, name: 'inbox_metric', value: 1.0)
      end

      it 'enqueues on the low queue' do
        expect { described_class.perform_later(inbox) }
          .to have_enqueued_job(described_class).with(inbox).on_queue('low')
      end

      it 'pre-deletes heavy associations and then destroys the object' do
        conv_ids = inbox.conversations.pluck(:id)
        ci_ids = inbox.contact_inboxes.pluck(:id)
        contact_ids = inbox.contacts.pluck(:id)
        re_ids = inbox.reporting_events.pluck(:id)

        described_class.perform_now(inbox)

        expect(Conversation.where(id: conv_ids)).to be_empty
        expect(ContactInbox.where(id: ci_ids)).to be_empty
        expect(ReportingEvent.where(id: re_ids)).to be_empty
        # Contacts should not be deleted for inbox destroy
        expect(Contact.where(id: contact_ids)).not_to be_empty
        expect { inbox.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when object is heavy (Account)' do
      let!(:account) { create(:account) }
      let!(:inbox1) { create(:inbox, account: account) }
      let!(:inbox2) { create(:inbox, account: account) }

      before do
        create_list(:conversation, 2, account: account, inbox: inbox1)
        create_list(:conversation, 1, account: account, inbox: inbox2)
        ReportingEvent.create!(account: account, name: 'acct_metric', value: 2.5)
        ReportingEvent.create!(account: account, inbox: inbox1, name: 'acct_inbox_metric', value: 3.5)
      end

      it 'pre-deletes conversations, contacts, inboxes and reporting events and then destroys the account' do
        conv_ids = account.conversations.pluck(:id)
        contact_ids = account.contacts.pluck(:id)
        inbox_ids = account.inboxes.pluck(:id)
        re_ids = account.reporting_events.pluck(:id)

        described_class.perform_now(account)

        expect(Conversation.where(id: conv_ids)).to be_empty
        expect(Contact.where(id: contact_ids)).to be_empty
        expect(Inbox.where(id: inbox_ids)).to be_empty
        expect(ReportingEvent.where(id: re_ids)).to be_empty
        expect { account.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when object is regular (Label)' do
      it 'just destroys the object' do
        label = create(:label)

        described_class.perform_now(label)

        expect { label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
