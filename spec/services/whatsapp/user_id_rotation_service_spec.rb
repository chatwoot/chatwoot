require 'rails_helper'

describe Whatsapp::UserIdRotationService do
  let!(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let!(:inbox) { channel.inbox }
  let(:payload) { { wa_id: '2423423243', user_id: { previous: 'IN.PREVIOUSBSUID', current: 'IN.CURRENTBSUID' } }.with_indifferent_access }

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

      described_class.new(inbox: inbox, payload: payload).perform

      expect(previous.reload.contact_id).not_to eq(claimed.contact_id)
    end

    it 'stays quiet when the row that won belongs to the same contact' do
      previous = create(:contact_inbox, inbox: inbox, source_id: 'IN.PREVIOUSBSUID')
      claimed = create(:contact_inbox, inbox: inbox, contact: previous.contact, source_id: 'IN.CURRENTBSUID')
      allow(inbox.contact_inboxes).to receive(:find_by).and_call_original
      allow(inbox.contact_inboxes).to receive(:find_by).with(source_id: 'IN.CURRENTBSUID').and_return(nil, claimed)
      allow(inbox.contact_inboxes).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

      expect(Rails.logger).not_to receive(:warn)

      described_class.new(inbox: inbox, payload: payload).perform
    end
  end
end
