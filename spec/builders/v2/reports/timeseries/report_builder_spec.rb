require 'rails_helper'

describe V2::Reports::Timeseries::ReportBuilder do
  describe 'average metrics' do
    subject { described_class.new(account, params) }

    let(:account) { create(:account) }
    let(:team) { create(:team, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:label) { create(:label, title: 'spec-billing', account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox, team: team) }
    let(:current_time) { '26.10.2020 10:00'.to_datetime }

    let(:params) do
      {
        type: filter_type,
        business_hours: business_hours,
        timezone_offset: timezone_offset,
        group_by: group_by,
        metric: metric,
        since: (current_time - 1.week).beginning_of_day.to_i.to_s,
        until: current_time.end_of_day.to_i.to_s,
        id: filter_id
      }
    end
    let(:timezone_offset) { nil }
    let(:group_by) { 'day' }
    let(:metric) { 'avg_first_response_time' }
    let(:business_hours) { false }
    let(:filter_type) { :account }
    let(:filter_id) { '' }

    before do
      travel_to current_time
      conversation.label_list.add(label.title)
      conversation.save!
      create(:reporting_event, name: 'first_response', value: 80, value_in_business_hours: 10, account: account, created_at: Time.zone.now,
                               conversation: conversation, inbox: inbox)
      create(:reporting_event, name: 'first_response', value: 100, value_in_business_hours: 20, account: account, created_at: 1.hour.ago)
      create(:reporting_event, name: 'first_response', value: 93, value_in_business_hours: 30, account: account, created_at: 1.week.ago)
    end

    describe '#timeseries' do
      it 'returns the correct values' do
        timeseries_values = subject.timeseries

        expect(timeseries_values).to eq(
          [
            { count: 1, timestamp: 1_603_065_600, value: 93.0 },
            { count: 0, timestamp: 1_603_152_000, value: 0 },
            { count: 0, timestamp: 1_603_238_400, value: 0 },
            { count: 0, timestamp: 1_603_324_800, value: 0 },
            { count: 0, timestamp: 1_603_411_200, value: 0 },
            { count: 0, timestamp: 1_603_497_600, value: 0 },
            { count: 0, timestamp: 1_603_584_000, value: 0 },
            { count: 2, timestamp: 1_603_670_400, value: 90.0 }
          ]
        )
      end

      context 'when business hours is provided' do
        let(:business_hours) { true }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries

          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: 1_603_065_600, value: 30.0 },
              { count: 0, timestamp: 1_603_152_000, value: 0 },
              { count: 0, timestamp: 1_603_238_400, value: 0 },
              { count: 0, timestamp: 1_603_324_800, value: 0 },
              { count: 0, timestamp: 1_603_411_200, value: 0 },
              { count: 0, timestamp: 1_603_497_600, value: 0 },
              { count: 0, timestamp: 1_603_584_000, value: 0 },
              { count: 2, timestamp: 1_603_670_400, value: 15.0 }
            ]
          )
        end
      end

      context 'when group_by is provided' do
        let(:group_by) { 'week' }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: (current_time - 1.week).beginning_of_week(:sunday).to_i, value: 93.0 },
              { count: 2, timestamp: current_time.beginning_of_week(:sunday).to_i, value: 90.0 }
            ]
          )
        end
      end

      context 'when timezone offset is provided' do
        let(:timezone_offset) { '5.5' }
        let(:group_by) { 'week' }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          expect(timeseries_values).to eq(
            [
              { count: 1, timestamp: (current_time - 1.week).in_time_zone('Chennai').beginning_of_week(:sunday).to_i, value: 93.0 },
              { count: 2, timestamp: current_time.in_time_zone('Chennai').beginning_of_week(:sunday).to_i, value: 90.0 }
            ]
          )
        end
      end

      context 'when the label filter is applied' do
        let(:group_by) { 'week' }
        let(:filter_type) { 'label' }
        let(:filter_id) { label.id }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          start_of_the_week = current_time.beginning_of_week(:sunday).to_i
          last_week_start_of_the_week = (current_time - 1.week).beginning_of_week(:sunday).to_i
          expect(timeseries_values).to eq(
            [
              { count: 0, timestamp: last_week_start_of_the_week, value: 0 },
              { count: 1, timestamp: start_of_the_week, value: 80.0 }
            ]
          )
        end
      end

      context 'when the inbox filter is applied' do
        let(:group_by) { 'week' }
        let(:filter_type) { 'inbox' }
        let(:filter_id) { inbox.id }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          start_of_the_week = current_time.beginning_of_week(:sunday).to_i
          last_week_start_of_the_week = (current_time - 1.week).beginning_of_week(:sunday).to_i
          expect(timeseries_values).to eq(
            [
              { count: 0, timestamp: last_week_start_of_the_week, value: 0 },
              { count: 1, timestamp: start_of_the_week, value: 80.0 }
            ]
          )
        end
      end

      context 'when the team filter is applied' do
        let(:group_by) { 'week' }
        let(:filter_type) { 'team' }
        let(:filter_id) { team.id }

        it 'returns correct timeseries' do
          timeseries_values = subject.timeseries
          start_of_the_week = current_time.beginning_of_week(:sunday).to_i
          last_week_start_of_the_week = (current_time - 1.week).beginning_of_week(:sunday).to_i
          expect(timeseries_values).to eq(
            [
              { count: 0, timestamp: last_week_start_of_the_week, value: 0 },
              { count: 1, timestamp: start_of_the_week, value: 80.0 }
            ]
          )
        end
      end
    end

    describe '#aggregate_value' do
      context 'when there is no filter applied' do
        it 'returns the correct average value' do
          expect(subject.aggregate_value).to eq 91.0
        end
      end

      context 'when rollups are enabled and the agent does not exist' do
        let(:filter_type) { :agent }
        let(:filter_id) { '999999' }
        let(:timezone_offset) { '0' }

        before do
          account.update!(reporting_timezone: 'Etc/UTC')
          allow(account).to receive(:feature_enabled?).with(:report_rollup).and_return(true)
        end

        it 'raises record not found to preserve raw path behavior' do
          expect { subject.aggregate_value }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'count metrics' do
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

      create(:account_user, account: account, user: user)
      create(:account_user, account: account2, user: user)

      conversation1 = create(:conversation, account: account, inbox: inbox, assignee: user)
      conversation2 = create(:conversation, account: account, inbox: inbox, assignee: user)

      conversation3 = create(:conversation, account: account2, inbox: inbox2, assignee: user)
      conversation4 = create(:conversation, account: account2, inbox: inbox2, assignee: user)

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
        expect(subject.aggregate_value).to eq(2)
      end

      context 'when rollups are enabled and the agent does not exist' do
        let(:timezone_offset) { '0' }

        let(:params) do
          super().merge(id: '999999')
        end

        before do
          account.update!(reporting_timezone: 'Etc/UTC')
          allow(account).to receive(:feature_enabled?).with(:report_rollup).and_return(true)
        end

        it 'raises record not found to preserve raw path behavior' do
          expect { subject.aggregate_value }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when querying account2' do
        subject { described_class.new(account2, params) }

        it 'returns only resolutions for account2' do
          expect(subject.aggregate_value).to eq(3)
        end
      end
    end

    describe '#timeseries' do
      it 'filters resolutions by account' do
        result = subject.timeseries
        total_count = result.sum { |row| row[:value] }
        expect(total_count).to eq(2)
      end
    end

    describe 'account isolation' do
      it 'does not leak data between accounts' do
        account1_count = described_class.new(account, params).aggregate_value
        account2_count = described_class.new(account2, params).aggregate_value

        expect(account1_count).to eq(2)
        expect(account2_count).to eq(3)
      end
    end
  end
end
