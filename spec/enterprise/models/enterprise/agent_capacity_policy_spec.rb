# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enterprise::AgentCapacityPolicy do
  let(:account) { create(:account) }
  let(:policy) { described_class.create!(account: account, name: 'Test Policy') }

  describe 'associations' do
    it 'belongs to account' do
      expect(policy.account).to eq(account)
    end

    it 'has many inbox capacity limits' do
      expect(policy).to respond_to(:inbox_capacity_limits)
    end

    it 'has many inboxes through inbox capacity limits' do
      expect(policy).to respond_to(:inboxes)
    end

    it 'has many account users' do
      expect(policy).to respond_to(:account_users)
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      invalid_policy = described_class.new(account: account)
      expect(invalid_policy).not_to be_valid
      expect(invalid_policy.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      invalid_policy = described_class.new(account: account, name: 'a' * 256)
      expect(invalid_policy).not_to be_valid
      expect(invalid_policy.errors[:name]).to include('is too long (maximum is 255 characters)')
    end
  end

  describe '#applicable_for_time?' do
    context 'when no exclusion rules' do
      it 'returns true' do
        expect(policy.applicable_for_time?).to be true
      end
    end

    context 'with hour exclusions' do
      let(:policy) do
        described_class.create!(
          account: account,
          name: 'Hour Exclusion Policy',
          exclusion_rules: { 'hours' => [10, 11, 12] }
        )
      end

      it 'returns false during excluded hours' do
        time = Time.zone.parse('10:30')
        expect(policy.applicable_for_time?(time)).to be false
      end

      it 'returns true outside excluded hours' do
        time = Time.zone.parse('13:30')
        expect(policy.applicable_for_time?(time)).to be true
      end
    end

    context 'with day exclusions' do
      let(:policy) do
        described_class.create!(
          account: account,
          name: 'Day Exclusion Policy',
          exclusion_rules: { 'days' => %w[saturday sunday] }
        )
      end

      it 'returns false on excluded days' do
        time = Time.zone.parse('2024-01-06 10:00') # Saturday
        expect(policy.applicable_for_time?(time)).to be false
      end

      it 'returns true on non-excluded days' do
        time = Time.zone.parse('2024-01-08 10:00') # Monday
        expect(policy.applicable_for_time?(time)).to be true
      end
    end
  end

  describe '#capacity_for_inbox' do
    let(:inbox) { create(:inbox, account: account) }

    it 'returns the conversation limit for the inbox' do
      Enterprise::InboxCapacityLimit.create!(
        agent_capacity_policy: policy,
        inbox: inbox,
        conversation_limit: 10
      )
      expect(policy.capacity_for_inbox(inbox)).to eq(10)
    end

    it 'returns nil for inbox without limit' do
      other_inbox = create(:inbox, account: account)
      expect(policy.capacity_for_inbox(other_inbox)).to be_nil
    end
  end

  describe '#overall_capacity' do
    context 'when overall_capacity is set' do
      let(:policy) do
        described_class.create!(
          account: account,
          name: 'Overall Capacity Policy',
          exclusion_rules: { 'overall_capacity' => 25 }
        )
      end

      it 'returns the overall capacity' do
        expect(policy.overall_capacity).to eq(25)
      end
    end

    context 'when overall_capacity is not set' do
      it 'returns infinity' do
        expect(policy.overall_capacity).to eq(Float::INFINITY)
      end
    end
  end
end
