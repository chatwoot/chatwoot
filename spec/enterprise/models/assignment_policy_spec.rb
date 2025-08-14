# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentPolicy, type: :model do
  let(:account) { create(:account) }

  describe 'balanced assignment order (Enterprise)' do
    it 'allows balanced assignment order' do
      policy = build(:assignment_policy, account: account, assignment_order: 'balanced')
      expect(policy).to be_valid
    end

    it 'can be created with balanced order' do
      policy = create(:assignment_policy,
                      account: account,
                      name: 'Balanced Policy',
                      assignment_order: 'balanced')

      expect(policy.persisted?).to be true
      expect(policy.assignment_order).to eq('balanced')
    end

    it 'can be updated from round_robin to balanced' do
      policy = create(:assignment_policy, account: account, assignment_order: 'round_robin')

      policy.update!(assignment_order: 'balanced')

      expect(policy.reload.assignment_order).to eq('balanced')
    end
  end

  describe 'enum values' do
    it 'includes balanced in assignment_order enum' do
      expect(described_class.assignment_orders).to include('balanced' => 1)
    end
  end
end
