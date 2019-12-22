require 'rails_helper'

describe ::ContactMergeAction do
  subject(:contact_merge) { described_class.new(base_contact, mergee_contact) }

  let!(:account) { create(:account) }
  let!(:base_contact) { create(:contact, account: account) }
  let!(:mergee_contact) { create(:contact, account: account) }

  before do
    2.times.each { create(:conversation, contact: mergee_contact) }
    2.times.each { create(:contact_inbox, contact: mergee_contact) }
  end

  describe '#perform' do
    context 'with conversations' do
      it 'moves the conversations to base contact' do
        contact_merge.perform
        expect(base_contact.conversations.count).to be 2
      end
    end

    context 'with contact inboxes' do
      it 'moves the contact inboxes to base contact' do
        contact_merge.perform
        expect(base_contact.contact_inboxes.count).to be 2
      end
    end
  end
end
