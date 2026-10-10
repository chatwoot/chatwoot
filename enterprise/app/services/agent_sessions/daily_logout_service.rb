class AgentSessions::DailyLogoutService
  pattr_initialize [:account!]

  def perform
    revoked_users = []
    account.with_lock do
      config = account.settings.fetch('daily_agent_logout')
      cutoff = logout_cutoff(config)
      next unless cutoff

      revoked_users = revoke_members(config, cutoff)
      account.update!(settings: account.settings.merge('daily_agent_logout' => config.merge('last_completed_on' => cutoff.to_date.iso8601)))
    end
    revoked_users.each do |pubsub_token, client_ids|
      ActionCable.server.broadcast(pubsub_token, { event: 'user:logout', data: { client_ids: client_ids } })
    end
    Rails.logger.info({ event: 'daily_agent_logout', account_id: account.id, users: revoked_users.length }.to_json) if revoked_users.any?
  end

  private

  def logout_cutoff(config)
    return unless config.fetch('enabled')

    now = Time.current.in_time_zone(config.fetch('timezone'))
    hour, minute = config.fetch('time').split(':').map(&:to_i)
    cutoff = now.change(hour: hour, min: minute, sec: 0)
    cutoff if now >= cutoff && config['last_completed_on'] != now.to_date.iso8601
  end

  def revoke_members(config, cutoff)
    inbox = account.inboxes.find(config.fetch('inbox_id'))
    role = account.custom_roles.find(config.fetch('custom_role_id'))
    members = account.account_users.where(custom_role: role, user_id: inbox.members.select(:id))
    members.includes(:user).filter_map { |member| revoke_sessions(member, cutoff) }
  end

  def revoke_sessions(member, cutoff)
    user = member.user
    user.with_lock do
      # A late/retried scheduler must preserve sessions opened after today's cutoff.
      newer_clients = user.user_sessions.where('created_at > ?', cutoff).pluck(:client_id)
      revoked_clients = user.tokens.keys - newer_clients
      member.update!(availability: :offline) if newer_clients.empty?
      next if revoked_clients.empty?

      user.update!(tokens: user.tokens.except(*revoked_clients))
      [user.pubsub_token, revoked_clients]
    end
  end
end
