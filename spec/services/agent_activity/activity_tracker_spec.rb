require 'rails_helper'

RSpec.describe AgentActivity::ActivityTracker do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe '.track_status_change' do
    it 'creates a new activity log when status changes to online' do
      expect do
        OnlineStatusTracker.set_status(account.id, user.id, 'online')
      end.to change(AgentActivityLog, :count).by(1)

      log = AgentActivityLog.last
      expect(log.user_id).to eq(user.id)
      expect(log.account_id).to eq(account.id)
      expect(log.status).to eq('online')
      expect(log.started_at).to be_present
      expect(log.ended_at).to be_nil
    end

    it 'closes previous log and creates new one when status changes' do
      OnlineStatusTracker.set_status(account.id, user.id, 'online')
      first_log = AgentActivityLog.last

      sleep 1

      OnlineStatusTracker.set_status(account.id, user.id, 'busy')

      first_log.reload
      expect(first_log.ended_at).to be_present
      expect(first_log.duration_seconds).to be > 0

      second_log = AgentActivityLog.last
      expect(second_log.status).to eq('busy')
      expect(second_log.ended_at).to be_nil
    end

    it 'does not create log for offline status' do
      OnlineStatusTracker.set_status(account.id, user.id, 'online')

      expect do
        OnlineStatusTracker.set_status(account.id, user.id, 'offline')
      end.not_to change(AgentActivityLog, :count)

      log = AgentActivityLog.last
      expect(log.ended_at).to be_present
    end

    it 'does not create duplicate logs if status does not change' do
      OnlineStatusTracker.set_status(account.id, user.id, 'online')

      expect do
        OnlineStatusTracker.set_status(account.id, user.id, 'online')
      end.not_to change(AgentActivityLog, :count)
    end
  end

  describe '.close_stale_logs' do
    it 'closes logs that are older than threshold' do
      log = create(:agent_activity_log,
                   account: account,
                   user: user,
                   status: 'online',
                   started_at: 2.hours.ago,
                   ended_at: nil)

      allow(OnlineStatusTracker).to receive(:get_presence).and_return(false)

      described_class.close_stale_logs

      log.reload
      expect(log.ended_at).to be_present
      expect(log.duration_seconds).to be_present
    end

    it 'does not close logs if user is still online' do
      log = create(:agent_activity_log,
                   account: account,
                   user: user,
                   status: 'online',
                   started_at: 2.hours.ago,
                   ended_at: nil)

      allow(OnlineStatusTracker).to receive(:get_presence).and_return(true)

      described_class.close_stale_logs

      log.reload
      expect(log.ended_at).to be_nil
    end
  end
end
