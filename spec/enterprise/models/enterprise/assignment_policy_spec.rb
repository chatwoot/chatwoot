# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::AssignmentPolicy, type: :module do
  let(:account) { create(:account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }

  before do
    assignment_policy.extend(described_class)
  end

  describe 'ASSIGNMENT_ORDERS constant' do
    it 'defines the correct assignment order mappings' do
      expect(Enterprise::AssignmentPolicy::ASSIGNMENT_ORDERS).to eq({
                                                                      'round_robin' => 0,
                                                                      'balanced' => 1
                                                                    })
    end

    it 'is frozen' do
      expect(Enterprise::AssignmentPolicy::ASSIGNMENT_ORDERS).to be_frozen
    end
  end

  describe '#assignment_order' do
    it 'returns round_robin for value 0' do
      assignment_policy.write_attribute(:assignment_order, 0)
      expect(assignment_policy.assignment_order).to eq('round_robin')
    end

    it 'returns balanced for value 1' do
      assignment_policy.write_attribute(:assignment_order, 1)
      expect(assignment_policy.assignment_order).to eq('balanced')
    end

    it 'defaults to round_robin for invalid values' do
      assignment_policy.write_attribute(:assignment_order, 999)
      expect(assignment_policy.assignment_order).to eq('round_robin')
    end

    it 'defaults to round_robin for nil values' do
      assignment_policy.write_attribute(:assignment_order, nil)
      expect(assignment_policy.assignment_order).to eq('round_robin')
    end
  end

  describe '#assignment_order=' do
    it 'sets the correct value for round_robin' do
      assignment_policy.assignment_order = 'round_robin'
      expect(assignment_policy.read_attribute(:assignment_order)).to eq(0)
    end

    it 'sets the correct value for balanced' do
      assignment_policy.assignment_order = 'balanced'
      expect(assignment_policy.read_attribute(:assignment_order)).to eq(1)
    end

    it 'defaults to 0 for invalid assignment order' do
      assignment_policy.assignment_order = 'invalid_order'
      expect(assignment_policy.read_attribute(:assignment_order)).to eq(0)
    end

    it 'defaults to 0 for nil assignment order' do
      assignment_policy.assignment_order = nil
      expect(assignment_policy.read_attribute(:assignment_order)).to eq(0)
    end
  end

  describe 'round trip conversion' do
    it 'maintains consistency for round_robin' do
      assignment_policy.assignment_order = 'round_robin'
      expect(assignment_policy.assignment_order).to eq('round_robin')
    end

    it 'maintains consistency for balanced' do
      assignment_policy.assignment_order = 'balanced'
      expect(assignment_policy.assignment_order).to eq('balanced')
    end
  end
end
