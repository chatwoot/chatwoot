require 'rails_helper'

RSpec.describe Label, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'title validations' do
    it 'would not let you start title without numbers or letters' do
      label = FactoryBot.build(:label, title: '_12')
      expect(label.valid?).to eq false
    end

    it 'would not let you use special characters' do
      label = FactoryBot.build(:label, title: 'jell;;2_12')
      expect(label.valid?).to eq false
    end

    it 'would not allow space' do
      label = FactoryBot.build(:label, title: 'heeloo _12')
      expect(label.valid?).to eq false
    end

    it 'allows foreign charactes' do
      label = FactoryBot.build(:label, title: '学中文_12')
      expect(label.valid?).to eq true
    end

    it 'converts uppercase letters to lowercase' do
      label = FactoryBot.build(:label, title: 'Hello_World')
      expect(label.valid?).to eq true
      expect(label.title).to eq 'hello_world'
    end

    it 'validates uniqueness of label name for account' do
      account = create(:account)
      label = FactoryBot.create(:label, account: account)
      duplicate_label = FactoryBot.build(:label, title: label.title, account: account)
      expect(duplicate_label.valid?).to eq false
    end
  end
end
