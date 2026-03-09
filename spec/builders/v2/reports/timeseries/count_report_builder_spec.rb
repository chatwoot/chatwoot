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
      since: since_time.beginning_of_day.to_i.to_s,
      until: current_time.end_of_day.to_i.to_s,
      timezone_offset: timezone_offset,
      group_by: group_by,
      id: user.id.to_s
    }
  end
  let(:group_by) { 'day' }
  let(:since_time) { current_time - 1.day }
  let(:timezone_offset) { nil }

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

    context 'when rollups are enabled and the agent does not exist' do
      let(:timezone_offset) { '0' }

      let(:params) do
        super().merge(id: '999999')
      end

      before do
        account.update!(reporting_timezone: 'Etc/UTC')
        allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(true)
      end

      it 'raises record not found to preserve raw path behavior' do
        expect { subject.aggregate_value }.to raise_error(ActiveRecord::RecordNotFound)
      end
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

    context 'when rollups are enabled and grouped by week' do
      let(:group_by) { 'week' }
      let(:current_time) { Time.zone.parse('2020-10-26 10:00:00 UTC') }
      let(:since_time) { current_time - 1.week }
      let(:timezone_offset) { '5.5' }

      before do
        account.update!(reporting_timezone: 'Chennai')
        allow(account).to receive(:feature_enabled?).with('reporting_events_rollup').and_return(true)

        create(:reporting_events_rollup,
               account: account,
               date: current_time.to_date - 1.day,
               dimension_type: 'agent',
               dimension_id: user.id,
               metric: 'resolutions_count',
               count: 1,
               sum_value: 0.0,
               sum_value_business_hours: 0.0)

        create(:reporting_events_rollup,
               account: account,
               date: current_time.to_date,
               dimension_type: 'agent',
               dimension_id: user.id,
               metric: 'resolutions_count',
               count: 1,
               sum_value: 0.0,
               sum_value_business_hours: 0.0)
      end

      it 'groups weeks using sunday boundaries' do
        expect(subject.timeseries).to eq(
          [
            { value: 0, timestamp: (current_time - 1.week).in_time_zone('Chennai').beginning_of_week(:sunday).to_i },
            { value: 2, timestamp: current_time.in_time_zone('Chennai').beginning_of_week(:sunday).to_i }
          ]
        )
      end
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
