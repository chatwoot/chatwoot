require 'rails_helper'

RSpec.describe DataImport::TagsManager do
  let!(:account) { create(:account) }
  let!(:contact) { create(:contact, account: account, identifier: '123') }

  before do
    account.labels.create!(title: 'ruby')
    account.labels.create!(title: 'rails')
  end

  describe '#build' do
    subject(:manager) { described_class.new(account) }

    context 'when tags param is blank' do
      it 'does nothing' do
        expect do
          manager.build(identifier: '123', tags: '')
        end.not_to(change { contact.reload.label_list })
      end
    end

    context 'when contact does not exist' do
      it 'does nothing' do
        expect do
          manager.build(identifier: '999', tags: 'ruby, rails')
        end.not_to(change { ActsAsTaggableOn::Tagging.count })
      end
    end

    context 'when tags are valid' do
      it 'assigns all tags to the contact' do
        manager.build(identifier: '123', tags: 'ruby, invalid_tag')

        expect(contact.reload.label_list).to match_array(%w[ruby invalid_tag])
      end
    end

    context 'when tags have spaces and case differences' do
      it 'normalizes tags before assignment' do
        manager.build(identifier: '123', tags: ' Ruby ,  RAILS ')

        expect(contact.reload.label_list).to match_array(%w[ruby rails])
      end
    end
  end
end
