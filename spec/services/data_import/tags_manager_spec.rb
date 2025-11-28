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
        end.not_to(change(ActsAsTaggableOn::Tagging, :count))
      end
    end

    context 'when tags are valid' do
      it 'builds taggings for valid tags only' do
        # 'ruby' and 'rails' labels already created in before block
        # ActsAsTaggableOn::Tags are created automatically via callback
        taggings = manager.build(identifier: '123', tags: 'ruby, invalid_tag')

        expect(taggings.size).to eq(1)
        expect(taggings.all?(ActsAsTaggableOn::Tagging)).to be true
        expect(taggings.map(&:taggable_id).uniq).to eq([contact.id])
        expect(taggings.first.tag_id).to eq(ActsAsTaggableOn::Tag.find_by(name: 'ruby').id)
      end
    end

    context 'when tags have spaces and case differences' do
      it 'normalizes tags before building taggings' do
        # Labels 'ruby' and 'rails' already created in before block
        # ActsAsTaggableOn::Tags are created automatically via callback
        taggings = manager.build(identifier: '123', tags: ' Ruby ,  RAILS ')

        expect(taggings.size).to eq(2)
        tag_names = taggings.map { |t| ActsAsTaggableOn::Tag.find(t.tag_id).name }
        expect(tag_names).to match_array(%w[ruby rails])
      end
    end

    context 'when finding contact by email' do
      let!(:email_contact) { create(:contact, account: account, email: 'test@example.com') }

      it 'finds and builds tagging for contact by email' do
        # Label 'ruby' already created in before block
        taggings = manager.build(email: 'test@example.com', tags: 'ruby')

        expect(taggings).not_to be_empty
        expect(taggings.first.taggable_id).to eq(email_contact.id)
      end
    end

    context 'when finding contact by phone number' do
      let!(:phone_contact) { create(:contact, account: account, phone_number: '+1234567890') }

      it 'finds and builds tagging for contact by phone number with plus sign' do
        # Label 'ruby' already created in before block
        taggings = manager.build(phone_number: '+1234567890', tags: 'ruby')

        expect(taggings).not_to be_empty
        expect(taggings.first.taggable_id).to eq(phone_contact.id)
      end

      it 'finds and builds tagging for contact by phone number without plus sign' do
        # Label 'ruby' already created in before block
        taggings = manager.build(phone_number: '1234567890', tags: 'ruby')

        expect(taggings).not_to be_empty
        expect(taggings.first.taggable_id).to eq(phone_contact.id)
      end
    end

    context 'when contact exists but tag does not exist in account' do
      it 'does not create tagging for non-existent tags' do
        taggings = manager.build(identifier: '123', tags: 'nonexistent')

        expect(taggings).to be_empty
      end
    end

    context 'when tags string has multiple formats' do
      it 'handles empty tags correctly' do
        # Labels 'ruby' and 'rails' already created in before block
        taggings = manager.build(identifier: '123', tags: 'ruby, , rails')

        expect(taggings.size).to eq(2)
      end

      it 'handles only commas' do
        taggings = manager.build(identifier: '123', tags: ',,,')

        expect(taggings).to be_empty
      end
    end
  end
end
