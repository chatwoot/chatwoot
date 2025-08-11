# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentV2::RateLimiter, type: :service do
  before do
    # Mock GlobalConfig to avoid InstallationConfig issues
    allow(GlobalConfig).to receive(:get).and_return({})

    # Ensure inbox_assignment_policy exists so the inbox has a policy
    inbox_assignment_policy
  end

  let(:account) { create(:account) }
  let(:policy) { create(:assignment_policy, account: account, fair_distribution_limit: 5, fair_distribution_window: 3600) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox_assignment_policy) { create(:inbox_assignment_policy, inbox: inbox, assignment_policy: policy) }
  let(:rate_limiter) { described_class.new(inbox: inbox, user: agent) }

  describe '#initialize' do
    it 'sets up rate limiter with inbox and user' do
      expect(rate_limiter.instance_variable_get(:@inbox)).to eq(inbox)
      expect(rate_limiter.instance_variable_get(:@user)).to eq(agent)
    end
  end

  describe '#within_limits?' do
    context 'when agent has no assignments in current window' do
      it 'returns true' do
        expect(rate_limiter.within_limits?).to be true
      end
    end

    context 'when agent is below limit' do
      before do
        # Create 3 conversations assigned to agent in current window
        3.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      it 'returns true' do
        expect(rate_limiter.within_limits?).to be true
      end
    end

    context 'when agent reaches limit' do
      before do
        # Create 5 conversations assigned to agent (at the limit)
        5.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      it 'returns false' do
        expect(rate_limiter.within_limits?).to be false
      end
    end

    context 'when agent exceeds limit' do
      before do
        # Create 6 conversations assigned to agent (exceeding the limit)
        6.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      it 'returns false' do
        expect(rate_limiter.within_limits?).to be false
      end
    end

    context 'when assignments are from different inbox' do
      let(:other_inbox) { create(:inbox, account: account) }

      before do
        # Create assignments in different inbox
        5.times do
          create(:conversation, inbox: other_inbox, assignee: agent, updated_at: Time.current)
        end
        # Create assignments in current inbox
        2.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      it 'only counts assignments from current inbox' do
        expect(rate_limiter.within_limits?).to be true
      end
    end

    context 'when assignments are outside time window' do
      before do
        # Create old assignments outside the window
        5.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: 2.hours.ago)
        end
        # Create recent assignments within the window
        2.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      it 'only counts assignments within time window' do
        expect(rate_limiter.within_limits?).to be true
      end
    end
  end

  describe '#status' do
    it 'returns correct status for agent with no assignments' do
      status = rate_limiter.status
      expect(status[:current_count]).to eq(0)
      expect(status[:within_limits]).to be true
      expect(status[:limit]).to eq(5)
    end

    it 'returns correct count after assignments' do
      3.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      status = rate_limiter.status
      expect(status[:current_count]).to eq(3)
      expect(status[:within_limits]).to be true
    end

    it 'includes reset_at time' do
      status = rate_limiter.status
      expect(status[:reset_at]).to be_a(Time)
      expect(status[:reset_at]).to be > Time.current
    end

    context 'when policy is disabled' do
      before do
        policy.update!(enabled: false)
      end

      it 'returns unlimited status' do
        status = rate_limiter.status
        expect(status[:within_limits]).to be true
        expect(status[:current_count]).to eq(0)
        expect(status[:limit]).to eq(Float::INFINITY)
        expect(status[:reset_at]).to be_nil
      end
    end

    context 'when no policy exists' do
      let(:inbox_without_policy) { create(:inbox, account: account) }
      let(:rate_limiter_no_policy) { described_class.new(inbox: inbox_without_policy, user: agent) }

      it 'returns unlimited status' do
        status = rate_limiter_no_policy.status
        expect(status[:within_limits]).to be true
        expect(status[:current_count]).to eq(0)
        expect(status[:limit]).to eq(Float::INFINITY)
        expect(status[:reset_at]).to be_nil
      end
    end
  end

  describe 'remaining assignments' do
    it 'returns full limit when no assignments made' do
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(5)
    end

    it 'returns correct remaining count' do
      2.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(3)
    end

    it 'returns 0 when limit reached' do
      5.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(0)
    end

    it 'returns negative when limit exceeded' do
      6.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      status = rate_limiter.status
      expect(status[:limit] - status[:current_count]).to eq(-1)
    end
  end

  describe 'assignment capacity checks' do
    it 'returns true when agent has remaining capacity' do
      2.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      expect(rate_limiter.within_limits?).to be true
    end

    it 'returns false when agent has no capacity' do
      5.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      expect(rate_limiter.within_limits?).to be false
    end

    it 'correctly tracks multiple assignments' do
      3.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end

      status = rate_limiter.status
      expect(status[:current_count]).to eq(3)
      expect(status[:within_limits]).to be true
      expect(status[:limit] - status[:current_count]).to eq(2)
    end
  end

  describe 'multiple agents' do
    let(:agent2) { create(:user, account: account) }
    let(:rate_limiter2) { described_class.new(inbox: inbox, user: agent2) }

    before do
      2.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      4.times do
        create(:conversation, inbox: inbox, assignee: agent2, updated_at: Time.current)
      end
    end

    it 'tracks status independently for each agent' do
      status1 = rate_limiter.status
      status2 = rate_limiter2.status

      expect(status1[:current_count]).to eq(2)
      expect(status1[:within_limits]).to be true
      expect(status1[:limit] - status1[:current_count]).to eq(3)

      expect(status2[:current_count]).to eq(4)
      expect(status2[:within_limits]).to be true
      expect(status2[:limit] - status2[:current_count]).to eq(1)
    end
  end

  describe 'window timing' do
    it 'calculates reset time correctly' do
      # Mock current time to make test predictable
      travel_to(Time.zone.parse('2024-01-01 10:30:00')) do
        status = rate_limiter.status
        reset_time = status[:reset_at]

        expect(reset_time).to be_a(Time)
        expect(reset_time).to be > Time.current
        expect(reset_time - Time.current).to be <= 3600
      end
    end
  end

  describe 'window boundaries' do
    it 'resets count in new window' do
      # Set up assignments in current window
      2.times do
        create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
      end
      expect(rate_limiter.status[:current_count]).to eq(2)

      # Travel to next window (advance by window size)
      travel(3601.seconds) do
        expect(rate_limiter.status[:current_count]).to eq(0)
        expect(rate_limiter.within_limits?).to be true
      end
    end

    it 'does not count assignments from previous window' do
      # Create assignments in previous window
      travel_to(2.hours.ago) do
        3.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
      end

      # Check current window
      expect(rate_limiter.status[:current_count]).to eq(0)
      expect(rate_limiter.within_limits?).to be true
    end
  end

  describe 'policy configuration' do
    context 'with different fair_distribution_limit' do
      let(:policy) { create(:assignment_policy, account: account, fair_distribution_limit: 10, fair_distribution_window: 3600) }

      it 'uses policy limit' do
        8.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
        expect(rate_limiter.within_limits?).to be true

        2.times do
          create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
        end
        expect(rate_limiter.within_limits?).to be false
      end
    end

    context 'with different fair_distribution_window' do
      let(:policy) { create(:assignment_policy, account: account, fair_distribution_limit: 5, fair_distribution_window: 7200) }

      it 'uses policy window' do
        # Create assignments 1.5 hours ago (within 2-hour window)
        travel_to(90.minutes.ago) do
          3.times do
            create(:conversation, inbox: inbox, assignee: agent, updated_at: Time.current)
          end
        end

        # These should still count toward the limit
        expect(rate_limiter.status[:current_count]).to eq(3)
        expect(rate_limiter.within_limits?).to be true
      end
    end
  end
end
