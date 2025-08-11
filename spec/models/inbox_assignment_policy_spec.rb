# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxAssignmentPolicy, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }
  let(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy) }

  describe 'associations' do
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:assignment_policy) }
  end

  describe 'validations' do
    subject { inbox_assignment_policy }

    it { is_expected.to validate_uniqueness_of(:inbox_id) }

    context 'with inbox and policy from different accounts' do
      let(:other_account) { create(:account) }
      let(:other_policy) { create(:assignment_policy, account: other_account) }

      it 'validates inbox belongs to same account as policy' do
        # Build without the factory callback that sets the accounts to be the same
        invalid_policy = described_class.new(inbox: inbox, assignment_policy: other_policy)

        expect(invalid_policy).not_to be_valid
        expect(invalid_policy.errors[:inbox]).to include('must belong to the same account as the assignment policy')
      end
    end
  end

  describe 'delegations' do
    it 'delegates account to inbox' do
      expect(inbox_assignment_policy.account).to eq(account)
    end

    it 'delegates policy attributes' do
      expect(inbox_assignment_policy.policy_name).to eq(assignment_policy.name)
      expect(inbox_assignment_policy.policy_description).to eq(assignment_policy.description)
      expect(inbox_assignment_policy.policy_assignment_order).to eq(assignment_policy.assignment_order)
      expect(inbox_assignment_policy.policy_conversation_priority).to eq(assignment_policy.conversation_priority)
      expect(inbox_assignment_policy.policy_fair_distribution_limit).to eq(assignment_policy.fair_distribution_limit)
      expect(inbox_assignment_policy.policy_fair_distribution_window).to eq(assignment_policy.fair_distribution_window)
      expect(inbox_assignment_policy.policy_enabled?).to eq(assignment_policy.enabled?)
    end
  end

  describe '#webhook_data' do
    it 'returns correct data structure' do
      data = inbox_assignment_policy.webhook_data

      expect(data).to include(
        id: inbox_assignment_policy.id,
        inbox_id: inbox.id,
        assignment_policy_id: assignment_policy.id
      )

      expect(data[:policy]).to eq(assignment_policy.webhook_data)
    end
  end

  describe 'business logic constraints' do
    it 'prevents multiple policies per inbox' do
      # Ensure first policy exists
      inbox_assignment_policy

      policy2 = create(:assignment_policy, account: account)

      # Try to create a second policy for the same inbox
      duplicate_policy = described_class.new(inbox: inbox, assignment_policy: policy2)
      expect(duplicate_policy).not_to be_valid
      expect(duplicate_policy.errors[:inbox_id]).to include('has already been taken')
    end

    it 'allows reassigning to different policy' do
      policy2 = create(:assignment_policy, account: account)

      expect do
        inbox_assignment_policy.update!(assignment_policy: policy2)
      end.not_to raise_error

      expect(inbox_assignment_policy.reload.assignment_policy).to eq(policy2)
    end
  end

  describe 'edge cases' do
    it 'handles nil associations gracefully' do
      # Build without saving to test nil handling
      policy = build(:inbox_assignment_policy, inbox: nil, assignment_policy: nil)

      expect { policy.valid? }.not_to raise_error
      expect(policy).not_to be_valid
    end

    it 'handles policy deletion cascade' do
      inbox_policy_id = inbox_assignment_policy.id

      # Deleting policy should delete inbox assignment
      assignment_policy.destroy!

      expect(described_class.find_by(id: inbox_policy_id)).to be_nil
    end

    it 'handles inbox deletion cascade' do
      inbox_policy_id = inbox_assignment_policy.id

      # Deleting inbox should delete inbox assignment
      inbox.destroy!

      expect(described_class.find_by(id: inbox_policy_id)).to be_nil
    end
  end
end
