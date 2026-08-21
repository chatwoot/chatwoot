require 'rails_helper'

describe Whatsapp::UserIdRotationService do
  let!(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let!(:inbox) { channel.inbox }
  let(:payload) { { wa_id: '2423423243', user_id: { previous: 'IN.PREVIOUSBSUID', current: 'IN.CURRENTBSUID' } }.with_indifferent_access }

  describe 'when a batch carries more than one rotation' do
    it 'acquires the mutex for the entries the job did not lock' do
      create(:contact_inbox, inbox: inbox, source_id: 'IN.FIRSTPREVIOUS')
      create(:contact_inbox, inbox: inbox, source_id: 'IN.SECONDPREVIOUS')
      batch = [
        { wa_id: '2423423243', user_id: { previous: 'IN.FIRSTPREVIOUS', current: 'IN.FIRSTCURRENT' } },
        { wa_id: '2423423243', user_id: { previous: 'IN.SECONDPREVIOUS', current: 'IN.SECONDCURRENT' } }
      ].map(&:with_indifferent_access)
      locks = []
      allow_any_instance_of(Redis::LockManager).to receive(:with_lock) do |_manager, key, _ttl, &block| # rubocop:disable RSpec/AnyInstance
        locks << key
        block.call
        true
      end

      described_class.new(inbox: inbox, updates: batch).perform

      # The job holds the key for the first entry, so only the second one has to be taken here.
      expect(locks).to contain_exactly(format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: inbox.id, sender_id: 'IN.SECONDCURRENT'))
    end
  end

  describe 'when the insert loses the uniqueness race' do
    it 'reports that the identifiers ended up on different contacts' do
      previous = create(:contact_inbox, inbox: inbox, source_id: 'IN.PREVIOUSBSUID')
      # The row a concurrent message created for its own contact: invisible when the service looks,
      # because that transaction had not committed, and present by the time the insert reaches the index.
      claimed = create(:contact_inbox, inbox: inbox, source_id: 'IN.CURRENTBSUID')
      allow(inbox.contact_inboxes).to receive(:find_by).and_call_original
      allow(inbox.contact_inboxes).to receive(:find_by).with(source_id: 'IN.CURRENTBSUID').and_return(nil, claimed)
      allow(inbox.contact_inboxes).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

      expect(Rails.logger).to receive(:warn).with(/IN.CURRENTBSUID already belongs to contact #{claimed.contact_id}/)

      described_class.new(inbox: inbox, updates: [payload]).perform

      expect(previous.reload.contact_id).not_to eq(claimed.contact_id)
    end

    it 'stays quiet when the row that won belongs to the same contact' do
      previous = create(:contact_inbox, inbox: inbox, source_id: 'IN.PREVIOUSBSUID')
      claimed = create(:contact_inbox, inbox: inbox, contact: previous.contact, source_id: 'IN.CURRENTBSUID')
      allow(inbox.contact_inboxes).to receive(:find_by).and_call_original
      allow(inbox.contact_inboxes).to receive(:find_by).with(source_id: 'IN.CURRENTBSUID').and_return(nil, claimed)
      allow(inbox.contact_inboxes).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

      expect(Rails.logger).not_to receive(:warn)

      described_class.new(inbox: inbox, updates: [payload]).perform
    end
  end
end
