require 'rails_helper'

describe V2::Reports::Timeseries::CountReportBuilder do
  subject { described_class.new(account, params) }

  let(:account) { create(:account) }
  let(:account2) { create(:account) }
  let(:user) { create(:user, email: 'agent1@example.com') }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox2) { create(:inbox, account: account2) }
  let(:current_time) { Time.current }

  let(:params) do
    {
      type: 'agent',
      metric: 'resolutions_count',
      since: (current_time - 1.day).beginning_of_day.to_i.to_s,
      until: current_time.end_of_day.to_i.to_s,
      id: user.id.to_s
    }
  end

  before do
    travel_to current_time

    # Add the same user to both accounts
    create(:account_user, account: account, user: user)
    create(:account_user, account: account2, user: user)

    # Create conversations in account1
    conversation1 = create(:conversation, account: account, inbox: inbox, assignee: user)
    conversation2 = create(:conversation, account: account, inbox: inbox, assignee: user)

    # Create conversations in account2
    conversation3 = create(:conversation, account: account2, inbox: inbox2, assignee: user)
    conversation4 = create(:conversation, account: account2, inbox: inbox2, assignee: user)

    # User resolves 2 conversations in account1
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account,
           user: user,
           conversation: conversation1,
           created_at: current_time - 12.hours)

    create(:reporting_event,
           name: 'conversation_resolved',
           account: account,
           user: user,
           conversation: conversation2,
           created_at: current_time - 6.hours)

    # Same user resolves 3 conversations in account2 - these should NOT be counted for account1
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account2,
           user: user,
           conversation: conversation3,
           created_at: current_time - 8.hours)

    create(:reporting_event,
           name: 'conversation_resolved',
           account: account2,
           user: user,
           conversation: conversation4,
           created_at: current_time - 4.hours)

    # Create another conversation in account2 for testing
    conversation5 = create(:conversation, account: account2, inbox: inbox2, assignee: user)
    create(:reporting_event,
           name: 'conversation_resolved',
           account: account2,
           user: user,
           conversation: conversation5,
           created_at: current_time - 2.hours)
  end

  describe '#aggregate_value' do
    it 'returns only resolutions performed by the user in the specified account' do
      # User should have 2 resolutions in account1, not 5 (total across both accounts)
      expect(subject.aggregate_value).to eq(2)
    end

    context 'when querying account2' do
      subject { described_class.new(account2, params) }

      it 'returns only resolutions for account2' do
        # User should have 3 resolutions in account2
        expect(subject.aggregate_value).to eq(3)
      end
    end
  end

  describe '#timeseries' do
    it 'filters resolutions by account' do
      result = subject.timeseries
      # Should only count the 2 resolutions from account1
      total_count = result.sum { |r| r[:value] }
      expect(total_count).to eq(2)
    end
  end

  describe 'account isolation' do
    it 'does not leak data between accounts' do
      # If account isolation works correctly, the counts should be different
      account1_count = described_class.new(account, params).aggregate_value
      account2_count = described_class.new(account2, params).aggregate_value

      expect(account1_count).to eq(2)
      expect(account2_count).to eq(3)
    end
  end
end
