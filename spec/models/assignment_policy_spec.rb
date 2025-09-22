require 'rails_helper'

RSpec.describe AssignmentPolicy do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:inbox_assignment_policies).dependent(:destroy) }
    it { is_expected.to have_many(:inboxes).through(:inbox_assignment_policies) }
  end

  describe 'validations' do
    subject { build(:assignment_policy) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
  end

  describe 'fair distribution validations' do
    it 'requires fair_distribution_limit to be greater than 0' do
      policy = build(:assignment_policy, fair_distribution_limit: 0)
      expect(policy).not_to be_valid
      expect(policy.errors[:fair_distribution_limit]).to include('must be greater than 0')
    end

    it 'requires fair_distribution_window to be greater than 0' do
      policy = build(:assignment_policy, fair_distribution_window: -1)
      expect(policy).not_to be_valid
      expect(policy.errors[:fair_distribution_window]).to include('must be greater than 0')
    end
  end

  describe 'enum values' do
    let(:assignment_policy) { create(:assignment_policy) }

    describe 'conversation_priority' do
      it 'can be set to earliest_created' do
        assignment_policy.update!(conversation_priority: :earliest_created)
        expect(assignment_policy.conversation_priority).to eq('earliest_created')
        expect(assignment_policy.earliest_created?).to be true
      end

      it 'can be set to longest_waiting' do
        assignment_policy.update!(conversation_priority: :longest_waiting)
        expect(assignment_policy.conversation_priority).to eq('longest_waiting')
        expect(assignment_policy.longest_waiting?).to be true
      end
    end

    describe 'assignment_order' do
      it 'can be set to round_robin' do
        assignment_policy.update!(assignment_order: :round_robin)
        expect(assignment_policy.assignment_order).to eq('round_robin')
        expect(assignment_policy.round_robin?).to be true
      end
    end
  end
end
