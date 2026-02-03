class AgentActivity::ActivityTracker
  def self.track_status_change(account_id, user_id, new_status)
    Rails.logger.info("[AgentActivity] track_status_change account_id=#{account_id} user_id=#{user_id} new_status=#{new_status}")

    now = Time.zone.now

    AgentActivityLog.close_open_logs(account_id, user_id, now)

    AgentActivityLog.where(account_id: account_id, user_id: user_id, duration_seconds: nil)
                    .where.not(ended_at: nil)
                    .find_each do |log|
      Rails.logger.debug { "[AgentActivity] finalize_log log_id=#{log.id} status=#{log.status}" }
      log.update(duration_seconds: (log.ended_at - log.started_at).to_i)
    end

    AgentActivityLog.create!(
      account_id: account_id,
      user_id: user_id,
      status: new_status,
      started_at: now,
      ended_at: (new_status == 'offline' ? now : nil)
    ).tap do |log|
      Rails.logger.info("[AgentActivity] created_log log_id=#{log.id} status=#{log.status}")
    end
  end

  def self.close_all_for_user(account_id, user_id)
    Rails.logger.info("[AgentActivity] close_all_for_user account_id=#{account_id} user_id=#{user_id}")
    AgentActivityLog.close_open_logs(account_id, user_id, Time.zone.now)
  end
end
