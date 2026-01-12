require 'rails_helper'

RSpec.describe AgentActivityLog, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:agent_activity_log, account: account, user: user) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:started_at) }

    it do
      expect(subject).to validate_inclusion_of(:status)
        .in_array(%w[online busy offline])
    end
  end

  describe 'callbacks' do
    describe '#calculate_duration' do
      it 'calculates duration_seconds when ended_at is set' do
        started_at = Time.zone.parse('2024-01-01 10:00:00')
        ended_at = Time.zone.parse('2024-01-01 11:00:00')

        log = create(
          :agent_activity_log,
          account: account,
          user: user,
          started_at: started_at,
          ended_at: ended_at
        )

        expect(log.duration_seconds).to eq(3600)
      end

      it 'does not calculate duration if ended_at is nil' do
        log = create(
          :agent_activity_log,
          account: account,
          user: user,
          started_at: Time.zone.now,
          ended_at: nil
        )

        expect(log.duration_seconds).to be_nil
      end
    end
  end

  describe 'scopes' do
    let!(:log_in_period) do
      create(
        :agent_activity_log,
        account: account,
        user: user,
        started_at: 2.hours.ago,
        ended_at: 1.hour.ago
      )
    end

    let!(:log_out_of_period) do
      create(
        :agent_activity_log,
        account: account,
        user: user,
        started_at: 10.hours.ago,
        ended_at: 9.hours.ago
      )
    end

    describe '.in_period' do
      it 'returns logs intersecting the given period' do
        result = described_class.in_period(3.hours.ago, Time.zone.now)

        expect(result).to include(log_in_period)
        expect(result).not_to include(log_out_of_period)
      end
    end

    describe '.for_user' do
      it 'returns logs for given user' do
        expect(described_class.for_user(user.id)).to contain_exactly(log_in_period, log_out_of_period)
      end
    end

    describe '.active_statuses' do
      before do
        described_class.delete_all

        create(:agent_activity_log, status: 'offline')
      end

      let!(:online_log) { create(:agent_activity_log, status: 'online') }
      let!(:busy_log)   { create(:agent_activity_log, status: 'busy') }

      it 'returns only online and busy logs' do
        expect(described_class.active_statuses)
          .to contain_exactly(online_log, busy_log)
      end
    end

    describe '.by_status' do
      it 'filters by status' do
        online_logs = described_class.by_status('online')

        expect(online_logs.all? { |l| l.status == 'online' }).to be(true)
      end
    end
  end

  describe '.close_open_logs' do
    let!(:open_log) do
      create(
        :agent_activity_log,
        account: account,
        user: user,
        ended_at: nil
      )
    end

    it 'closes all open logs for account and user' do
      ended_at = Time.zone.now

      described_class.close_open_logs(account.id, user.id, ended_at)

      expect(open_log.reload.ended_at).to be_within(1.second).of(ended_at)
    end
  end

  describe '#active?' do
    it 'returns true for online status' do
      log = build(:agent_activity_log, status: 'online')
      expect(log.active?).to be(true)
    end

    it 'returns true for busy status' do
      log = build(:agent_activity_log, status: 'busy')
      expect(log.active?).to be(true)
    end

    it 'returns false for offline status' do
      log = build(:agent_activity_log, status: 'offline')
      expect(log.active?).to be(false)
    end
  end
end
