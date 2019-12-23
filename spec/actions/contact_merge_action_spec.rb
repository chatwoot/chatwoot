require 'rails_helper'

describe ::ContactMergeAction do
  subject(:contact_merge) { described_class.new(base_contact: base_contact, mergee_contact: mergee_contact).perform }

  let!(:account) { create(:account) }
  let!(:base_contact) { create(:contact, account: account) }
  let!(:mergee_contact) { create(:contact, account: account) }

  before do
    2.times.each { create(:conversation, contact: mergee_contact) }
    2.times.each { create(:contact_inbox, contact: mergee_contact) }
  end

  describe '#perform' do
    it 'deletes mergee_contact' do
      contact_merge
      expect { mergee_contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when mergee contact with conversations' do
      it 'moves the conversations to base contact' do
        contact_merge
        expect(base_contact.conversations.count).to be 2
      end
    end

    context 'when mergee contact with contact inboxes' do
      it 'moves the contact inboxes to base contact' do
        contact_merge
        expect(base_contact.contact_inboxes.count).to be 2
      end
    end
  end
end
