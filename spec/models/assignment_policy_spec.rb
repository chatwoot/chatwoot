# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentPolicy, type: :model do
  let(:account) { create(:account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inbox_assignment_policies).dependent(:destroy) }
    it { is_expected.to have_many(:inboxes).through(:inbox_assignment_policies) }
  end

  describe 'validations' do
    subject { assignment_policy }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }

    it { is_expected.to validate_presence_of(:fair_distribution_limit) }
    it { is_expected.to validate_numericality_of(:fair_distribution_limit).is_greater_than(0).is_less_than_or_equal_to(100) }

    it { is_expected.to validate_presence_of(:fair_distribution_window) }
    it { is_expected.to validate_numericality_of(:fair_distribution_window).is_greater_than(60).is_less_than_or_equal_to(86_400) }

    context 'with balanced assignment validation' do
      let(:enterprise_account) { create(:account) }

      before do
        allow(enterprise_account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
      end

      it 'allows balanced assignment for enterprise accounts' do
        policy = build(:assignment_policy, account: enterprise_account, assignment_order: :balanced)
        expect(policy).to be_valid
      end

      it 'rejects balanced assignment for non-enterprise accounts' do
        policy = build(:assignment_policy, account: account, assignment_order: :balanced)
        expect(policy).not_to be_valid
        expect(policy.errors[:assignment_order]).to include('Balanced assignment is only available for enterprise accounts')
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:assignment_order).with_values(round_robin: 0, balanced: 1) }
    it { is_expected.to define_enum_for(:conversation_priority).with_values(earliest_created: 0, longest_waiting: 1) }
  end

  describe 'scopes' do
    let!(:enabled_policy) { create(:assignment_policy, account: account, enabled: true) }
    let!(:disabled_policy) { create(:assignment_policy, account: account, enabled: false) }

    it 'filters enabled policies' do
      expect(described_class.enabled).to include(enabled_policy)
      expect(described_class.enabled).not_to include(disabled_policy)
    end

    it 'filters disabled policies' do
      expect(described_class.disabled).to include(disabled_policy)
      expect(described_class.disabled).not_to include(enabled_policy)
    end
  end

  describe '#can_use_balanced_assignment?' do
    context 'when account has enterprise agent capacity feature' do
      before do
        allow(account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(true)
      end

      it 'returns true' do
        expect(assignment_policy.can_use_balanced_assignment?).to be true
      end
    end

    context 'when account does not have enterprise features' do
      before do
        allow(account).to receive(:feature_enabled?).with(:enterprise_agent_capacity).and_return(false)
      end

      it 'returns false' do
        expect(assignment_policy.can_use_balanced_assignment?).to be false
      end
    end
  end

  describe '#webhook_data' do
    it 'returns correct data structure' do
      data = assignment_policy.webhook_data

      expect(data).to include(
        id: assignment_policy.id,
        name: assignment_policy.name,
        description: assignment_policy.description,
        assignment_order: assignment_policy.assignment_order,
        conversation_priority: assignment_policy.conversation_priority,
        fair_distribution_limit: assignment_policy.fair_distribution_limit,
        fair_distribution_window: assignment_policy.fair_distribution_window,
        enabled: assignment_policy.enabled
      )
    end
  end
end
