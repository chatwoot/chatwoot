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

  describe 'assignment order constants' do
    it 'includes balanced in ASSIGNMENT_ORDERS constant' do
      expect(Enterprise::AssignmentPolicy::ASSIGNMENT_ORDERS).to include('balanced' => 1)
      expect(Enterprise::AssignmentPolicy::ASSIGNMENT_ORDERS).to include('round_robin' => 0)
    end
  end
end
