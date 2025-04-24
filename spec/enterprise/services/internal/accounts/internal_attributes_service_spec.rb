require 'rails_helper'

RSpec.describe Internal::Accounts::InternalAttributesService do
  let!(:account) { create(:account, internal_attributes: { 'test_key' => 'test_value' }) }
  let(:service) { described_class.new(account) }
  let(:business_features) { Enterprise::Billing::HandleStripeEventService::BUSINESS_PLAN_FEATURES }
  let(:enterprise_features) { Enterprise::Billing::HandleStripeEventService::ENTERPRISE_PLAN_FEATURES }

  describe '#initialize' do
    it 'sets the account' do
      expect(service.account).to eq(account)
    end
  end

  describe '#get' do
    it 'returns the value for a valid key' do
      # Manually set the value first since the key needs to be in VALID_KEYS
      allow(service).to receive(:validate_key!).and_return(true)
      account.internal_attributes['manually_managed_features'] = ['test']

      expect(service.get('manually_managed_features')).to eq(['test'])
    end

    it 'raises an error for an invalid key' do
      expect { service.get('invalid_key') }.to raise_error(ArgumentError, 'Invalid internal attribute key: invalid_key')
    end
  end

  describe '#set' do
    it 'sets the value for a valid key' do
      # Stub the validation to allow our test key
      allow(service).to receive(:validate_key!).and_return(true)

      service.set('manually_managed_features', %w[feature1 feature2])
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq(%w[feature1 feature2])
    end

    it 'raises an error for an invalid key' do
      expect { service.set('invalid_key', 'value') }.to raise_error(ArgumentError, 'Invalid internal attribute key: invalid_key')
    end

    it 'creates internal_attributes hash if it is empty' do
      account.update(internal_attributes: {})

      # Stub the validation to allow our test key
      allow(service).to receive(:validate_key!).and_return(true)

      service.set('manually_managed_features', ['feature1'])
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq(['feature1'])
    end
  end

  describe '#manually_managed_features' do
    it 'returns an empty array when no features are set' do
      expect(service.manually_managed_features).to eq([])
    end

    it 'returns the features when they are set' do
      account.update(internal_attributes: { 'manually_managed_features' => %w[feature1 feature2] })

      expect(service.manually_managed_features).to eq(%w[feature1 feature2])
    end
  end

  describe '#manually_managed_features=' do
    # Use a real SLA feature which is in the BUSINESS_PLAN_FEATURES
    let(:valid_feature) { 'sla' }

    before do
      # Make sure the feature is allowed through validation
      allow(service).to receive(:valid_feature_list).and_return([valid_feature, 'custom_roles'])
    end

    it 'saves features as an array' do
      service.manually_managed_features = valid_feature
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature])
    end

    it 'handles nil input' do
      service.manually_managed_features = nil
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([])
    end

    it 'handles array input' do
      service.manually_managed_features = [valid_feature, 'custom_roles']
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature, 'custom_roles'])
    end

    it 'filters out invalid features' do
      service.manually_managed_features = [valid_feature, 'invalid_feature']
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature])
    end

    it 'removes duplicates' do
      service.manually_managed_features = [valid_feature, valid_feature]
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature])
    end

    it 'removes empty strings' do
      service.manually_managed_features = [valid_feature, '', '  ']
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature])
    end

    it 'trims whitespace' do
      service.manually_managed_features = ["  #{valid_feature}  "]
      account.reload

      expect(account.internal_attributes['manually_managed_features']).to eq([valid_feature])
    end
  end

  describe '#valid_feature_list' do
    it 'returns a combination of business and enterprise features' do
      expect(service.valid_feature_list).to include(*business_features)
      expect(service.valid_feature_list).to include(*enterprise_features)
    end
  end
end
