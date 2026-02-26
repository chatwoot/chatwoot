# == Schema Information
#
# Table name: labels
#
#  id                :bigint           not null, primary key
#  allow_auto_assign :boolean          default(FALSE)
#  color             :string           default("#1f93ff"), not null
#  description       :text
#  show_on_sidebar   :boolean
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint
#
# Indexes
#
#  index_labels_on_account_id            (account_id)
#  index_labels_on_allow_auto_assign     (allow_auto_assign)
#  index_labels_on_title_and_account_id  (title,account_id) UNIQUE
#
require 'rails_helper'

RSpec.describe Label do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'title validations' do
    it 'would not let you start title without numbers or letters' do
      label = FactoryBot.build(:label, title: '_12')
      expect(label.valid?).to be false
    end

    it 'would not let you use special characters' do
      label = FactoryBot.build(:label, title: 'jell;;2_12')
      expect(label.valid?).to be false
    end

    it 'would not allow space' do
      label = FactoryBot.build(:label, title: 'heeloo _12')
      expect(label.valid?).to be false
    end

    it 'allows foreign charactes' do
      label = FactoryBot.build(:label, title: '学中文_12')
      expect(label.valid?).to be true
    end

    it 'converts uppercase letters to lowercase' do
      label = FactoryBot.build(:label, title: 'Hello_World')
      expect(label.valid?).to be true
      expect(label.title).to eq 'hello_world'
    end

    it 'validates uniqueness of label name for account' do
      account = create(:account)
      label = FactoryBot.create(:label, account: account)
      duplicate_label = FactoryBot.build(:label, title: label.title, account: account)
      expect(duplicate_label.valid?).to be false
    end
  end

  describe '.after_update_commit' do
    let(:label) { create(:label) }

    it 'calls update job' do
      expect(Labels::UpdateJob).to receive(:perform_later).with('new-title', label.title, label.account_id)

      label.update(title: 'new-title')
    end

    it 'does not call update job if title is not updated' do
      expect(Labels::UpdateJob).not_to receive(:perform_later)

      label.update(description: 'new-description')
    end
  end
end
