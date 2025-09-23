require 'rails_helper'

RSpec.describe DataImport::ContactManager do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:manager) { described_class.new(account) }

  describe '#update_contact_with_merged_attributes' do
    context 'when tags are provided' do
      before do
        create(:label, account: account, title: 'ruby')
        create(:label, account: account, title: 'rails')
      end

      it 'assigns only valid tags to the contact' do
        params = { tags: 'ruby, rails, invalid,  RAILS  ' }

        manager.update_contact_with_merged_attributes(params, contact)

        expect(contact.reload.label_list).to match_array(%w[ruby rails])
      end
    end

    context 'when no tags are provided' do
      it 'assigns an empty tag list' do
        params = { tags: '' }

        manager.update_contact_with_merged_attributes(params, contact)

        expect(contact.reload.label_list).to eq([])
      end
    end

    context 'when tags param is nil' do
      it 'assigns an empty tag list' do
        params = {}

        manager.update_contact_with_merged_attributes(params, contact)

        expect(contact.reload.label_list).to eq([])
      end
    end
  end
end
