require 'rails_helper'

describe ContactMergeAction do
  subject(:contact_merge) { described_class.new(account: account, base_contact: base_contact, mergee_contact: mergee_contact).perform }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:base_contact) { create(:contact, account: account) }
  let!(:mergee_contact) { create(:contact, account: account) }

  describe '#perform' do
    context 'when mergee contact has calls' do
      let!(:mergee_call) do
        conversation = create(:conversation, account: account, inbox: inbox, contact: mergee_contact)
        create(:call, account: account, inbox: inbox, conversation: conversation, contact: mergee_contact)
      end

      it 'moves the calls to base contact' do
        contact_merge
        expect(mergee_call.reload.contact_id).to eq(base_contact.id)
      end
    end
  end
end
