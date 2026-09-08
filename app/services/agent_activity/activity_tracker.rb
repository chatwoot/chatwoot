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

  def self.track_presence_reconnect(account_id, user_id, expired_at, reconnected_at)
    account_user = AccountUser.find_by(account_id: account_id, user_id: user_id)
    return false unless account_user&.auto_offline?

    account_user.with_lock do
      current_expiry = OnlineStatusTracker.get_presence_expiry(account_id, 'User', user_id)
      return false unless current_expiry == expired_at

      restart_presence_interval(account_user, expired_at, reconnected_at) if expired_at
      yield
      account_user.account.enqueue_queue_processing if account_user.online?
      true
    end
  end

  def self.restart_presence_interval(account_user, expired_at, reconnected_at)
    account_id = account_user.account_id
    user_id = account_user.user_id
    open_log = AgentActivityLog.where(account_id: account_id, user_id: user_id, ended_at: nil).order(:started_at).last
    return if open_log&.started_at&.after?(expired_at)

    open_log&.update!(ended_at: expired_at)
    status = account_user.availability
    AgentActivityLog.create!(account_id: account_id, user_id: user_id, status: status, started_at: reconnected_at,
                             ended_at: (status == 'offline' ? reconnected_at : nil))
  end
  private_class_method :restart_presence_interval

  def self.close_expired_presence(account_id, user_id, expired_at)
    account_user = AccountUser.find_by(account_id: account_id, user_id: user_id)
    return unless account_user&.auto_offline?

    account_user.with_lock do
      current_expiry = OnlineStatusTracker.get_presence_expiry(account_id, 'User', user_id)
      return unless current_expiry == expired_at && current_expiry <= Time.zone.now

      AgentActivityLog.where(account_id: account_id, user_id: user_id, ended_at: nil)
                      .where('started_at <= ?', expired_at)
                      .find_each { |log| log.update!(ended_at: expired_at) }
    end
  end
end
