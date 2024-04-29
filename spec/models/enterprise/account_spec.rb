require 'rails_helper'

RSpec.describe Enterprise::Account do
  describe '#subscribed_features' do
    let(:account) { create(:account) }
    let(:plan_features) do
      {
        'hacker' => %w[feature1 feature2],
        'startups' => %w[feature1 feature2 feature3 feature4]
      }
    end

    before do
      InstallationConfig.where(name: 'CHATWOOT_CLOUD_PLAN_FEATURES').first_or_create(value: plan_features)
    end

    context 'when plan_name is hacker' do
      it 'returns the features for the hacker plan' do
        account.custom_attributes = { 'plan_name': 'hacker' }
        account.save!

        expect(account.subscribed_features).to eq(%w[feature1 feature2])
      end
    end

    context 'when plan_name is startups' do
      it 'returns the features for the startups plan' do
        account.custom_attributes = { 'plan_name': 'startups' }
        account.save!

        expect(account.subscribed_features).to eq(%w[feature1 feature2 feature3 feature4])
      end
    end

    context 'when plan_features is blank' do
      it 'returns an empty array' do
        account.custom_attributes = {}
        account.save!

        expect(account.subscribed_features).to be_nil
      end
    end
  end
end
