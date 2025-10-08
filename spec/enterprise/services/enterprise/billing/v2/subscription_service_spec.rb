require 'rails_helper'

describe Enterprise::Billing::V2::SubscriptionService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:config) { Rails.application.config.stripe_v2 }

  around do |example|
    original_config = config.deep_dup
    example.run
    config.replace(original_config)
  end

  before do
    config[:plans] ||= {}
    config[:plans][:startup] = {
      monthly_credits: 800,
      pricing_plan_id: 'plan_startup'
    }
  end

  describe '#migrate_to_v2' do
    it 'updates account attributes and logs initial credit grant' do # rubocop:disable RSpec/MultipleExpectations
      result = nil

      expect do
        result = service.migrate_to_v2(plan_type: 'startup')
      end.to change { account.reload.credit_transactions.count }.by(1)

      account.reload
      expect(result).to include(success: true)
      expect(account.custom_attributes['stripe_billing_version']).to eq(2)
      expect(account.custom_attributes['monthly_credits']).to eq(800)
      expect(account.custom_attributes['plan_name']).to eq('Startup')

      transaction = account.credit_transactions.order(created_at: :desc).first
      expect(transaction.amount).to eq(800)
      expect(transaction.metadata['source']).to eq('migration')
      expect(transaction.metadata['plan_type']).to eq('startup')
    end

    it 'returns error when already on v2' do
      account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_billing_version' => 2))

      result = service.migrate_to_v2

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('Already on V2')
    end
  end

  describe '#update_plan' do
    it 'updates plan name when on v2 billing' do
      account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_billing_version' => 2))

      result = service.update_plan('business')

      expect(result).to include(success: true, plan: 'business')
      expect(account.reload.custom_attributes['plan_name']).to eq('Business')
    end

    it 'returns error when account not migrated' do
      result = service.update_plan('business')

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('Not on V2 billing')
    end
  end
end
