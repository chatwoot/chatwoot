require 'rails_helper'

RSpec.describe DeleteObjectJob, type: :job do
  describe '#perform' do
    context 'heavy object (Inbox)' do
      let!(:account) { create(:account) }
      let!(:inbox) { create(:inbox, account: account) }

      before do
        create_list(:conversation, 3, account: account, inbox: inbox)
      end

      it 'enqueues on the low queue' do
        expect { described_class.perform_later(inbox) }
          .to have_enqueued_job(described_class).with(inbox).on_queue('low')
      end

      it 'pre-deletes heavy associations and then destroys the object' do
        conv_ids = inbox.conversations.pluck(:id)
        ci_ids = inbox.contact_inboxes.pluck(:id)
        contact_ids = inbox.contacts.pluck(:id)

        described_class.perform_now(inbox)

        expect(Conversation.where(id: conv_ids)).to be_empty
        expect(ContactInbox.where(id: ci_ids)).to be_empty
        # Contacts should not be deleted for inbox destroy
        expect(Contact.where(id: contact_ids)).not_to be_empty
        expect { inbox.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'pre-purge timing' do
        it 'removes associations during pre-purge, independent of final destroy' do
          conv_ids = inbox.conversations.pluck(:id)
          ci_ids = inbox.contact_inboxes.pluck(:id)
          contact_ids = inbox.contacts.pluck(:id)

          # Prevent the final destroy! to isolate pre-purge effects
          allow(inbox).to receive(:destroy!).and_raise(StandardError, 'halt-after-purge')

          expect { described_class.perform_now(inbox) }.to raise_error(StandardError, 'halt-after-purge')

          # Inbox still exists since destroy! was halted
          expect(inbox.reload).to be_present
          # But heavy associations were purged by the job before destroy!
          expect(Conversation.where(id: conv_ids)).to be_empty
          expect(ContactInbox.where(id: ci_ids)).to be_empty
          # Contacts should not be deleted for inbox destroy path
          expect(Contact.where(id: contact_ids)).not_to be_empty
        end
      end
    end

    context 'regular object (Label)' do
      it 'just destroys the object without batched purges' do
        label = create(:label)
        expect_any_instance_of(described_class).not_to receive(:batch_destroy)

        described_class.perform_now(label)

        expect { label.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
