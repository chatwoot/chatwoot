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

  # CommMate: Tests for campaign labels
  describe '.campaign_labels scope' do
    let(:account) { create(:account) }
    let!(:campaign_label) { create(:label, account: account, available_for_campaigns: true) }
    let!(:non_campaign_label) { create(:label, account: account, available_for_campaigns: false) }

    it 'returns only labels with available_for_campaigns true' do
      campaign_labels = account.labels.campaign_labels
      expect(campaign_labels).to include(campaign_label)
      expect(campaign_labels).not_to include(non_campaign_label)
    end

    it 'returns empty when no campaign labels exist' do
      campaign_label.destroy
      expect(account.labels.campaign_labels).to be_empty
    end
  end

  describe 'available_for_campaigns attribute' do
    it 'defaults to false' do
      label = create(:label)
      expect(label.available_for_campaigns).to be false
    end

    it 'can be set to true' do
      label = create(:label, available_for_campaigns: true)
      expect(label.available_for_campaigns).to be true
    end
  end
end
