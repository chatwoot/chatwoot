require 'rails_helper'

RSpec.describe PlanConfig do
  describe '.all' do
    it 'returns all 4 plans' do
      plans = described_class.all
      expect(plans.length).to eq(4)
      expect(plans).to all(be_a(PlanConfig))
    end

    it 'includes both basic and pro tiers' do
      tiers = described_class.all.map(&:tier).uniq.sort
      expect(tiers).to eq(%w[basic pro])
    end
  end

  describe '.find' do
    it 'returns a PlanConfig for a valid plan key' do
      plan = described_class.find('pro_monthly')
      expect(plan).to be_a(PlanConfig)
      expect(plan.key).to eq('pro_monthly')
      expect(plan.name).to eq('Pro')
      expect(plan.tier).to eq('pro')
      expect(plan.interval).to eq('month')
      expect(plan.amount_kd).to eq(75)
    end

    it 'raises ArgumentError for an unknown plan key' do
      expect { described_class.find('nonexistent') }.to raise_error(ArgumentError, /Unknown plan/)
    end
  end

  describe '.for_price' do
    it 'finds a plan by its Stripe price ID' do
      plan = described_class.for_price('price_pro_monthly_test')
      expect(plan).to be_a(PlanConfig)
      expect(plan.key).to eq('pro_monthly')
    end

    it 'returns nil for an unknown Stripe price ID' do
      expect(described_class.for_price('price_nonexistent')).to be_nil
    end
  end

  describe 'plan attributes' do
    let(:basic) { described_class.find('basic_monthly') }
    let(:pro) { described_class.find('pro_monthly') }

    it 'exposes ai_response_limit from limits' do
      expect(basic.ai_response_limit).to eq(10_000)
      expect(pro.ai_response_limit).to eq(25_000)
    end

    it 'exposes kb_document_limit from limits' do
      expect(basic.kb_document_limit).to eq(100)
      expect(pro.kb_document_limit).to eq(200)
    end

    it 'reports stripe_price_id from env with defaults' do
      expect(basic.stripe_price_id).to eq('price_basic_monthly_test')
    end
  end

  describe '#feature_enabled?' do
    let(:basic) { described_class.find('basic_monthly') }
    let(:pro) { described_class.find('pro_monthly') }

    it 'returns false for features not included in basic' do
      expect(basic.feature_enabled?(:crm_integration)).to be false
      expect(basic.feature_enabled?(:api_access)).to be false
    end

    it 'returns true for features included in pro' do
      expect(pro.feature_enabled?(:crm_integration)).to be true
      expect(pro.feature_enabled?(:api_access)).to be true
    end

    it 'returns false for unknown features' do
      expect(pro.feature_enabled?(:nonexistent_feature)).to be false
    end
  end

  describe '#basic? and #pro?' do
    it 'identifies basic plans' do
      plan = described_class.find('basic_monthly')
      expect(plan.basic?).to be true
      expect(plan.pro?).to be false
    end

    it 'identifies pro plans' do
      plan = described_class.find('pro_annual')
      expect(plan.pro?).to be true
      expect(plan.basic?).to be false
    end
  end

  describe '#to_h' do
    it 'serializes plan to a hash' do
      plan = described_class.find('pro_monthly')
      hash = plan.to_h

      expect(hash[:key]).to eq('pro_monthly')
      expect(hash[:name]).to eq('Pro')
      expect(hash[:tier]).to eq('pro')
      expect(hash[:interval]).to eq('month')
      expect(hash[:amount_kd]).to eq(75)
      expect(hash[:limits]).to include(ai_responses_per_month: 25_000)
      expect(hash[:features]).to include(crm_integration: true)
    end
  end

  describe 'annual plans' do
    it 'has correct pricing for basic annual' do
      plan = described_class.find('basic_annual')
      expect(plan.amount_kd).to eq(600)
      expect(plan.interval).to eq('year')
    end

    it 'has correct pricing for pro annual' do
      plan = described_class.find('pro_annual')
      expect(plan.amount_kd).to eq(900)
      expect(plan.interval).to eq('year')
    end
  end

  describe 'env var override' do
    it 'uses env var for stripe_price_id when set' do
      with_modified_env(STRIPE_PRO_MONTHLY_PRICE_ID: 'price_live_xxx') do
        # Force reload since PLANS is frozen at boot time
        plans = YAML.safe_load(
          ERB.new(Rails.root.join('config/plans.yml').read).result,
          permitted_classes: [], aliases: true
        ).fetch('plans')
        plan = PlanConfig.new('pro_monthly', plans['pro_monthly'])
        expect(plan.stripe_price_id).to eq('price_live_xxx')
      end
    end
  end
end
