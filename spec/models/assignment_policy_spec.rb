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
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:assignment_order).with_values(round_robin: 0) }
    it { is_expected.to define_enum_for(:conversation_priority).with_values(earliest_created: 0, longest_waiting: 1) }
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
