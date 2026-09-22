module SignInSessionLimitable
  PICKER_SESSION_FIELDS = %i[id browser_name browser_version device_name platform_name platform_version
                             ip_address city country last_activity_at created_at].freeze

  private

  def sessions_limit_reached?(user)
    limit = ENV.fetch('MAX_USER_SESSIONS', 25).to_i
    active_token_count(user) >= limit
  end

  def active_token_count(user)
    now = Time.current.to_i
    (user.tokens || {}).count { |_, v| v['expiry'].to_i > now }
  end

  # Returns true when a response has been rendered (e.g., 409 picker). Non-browser clients
  # auto-evict instead of getting stuck on a UI they can't render.
  def enforce_session_limit_for_password_login(user)
    if revoking_sessions?
      revoke_sessions_for_login(user)
      return false
    end

    return false unless sessions_limit_reached?(user)

    # Picker only when every token has a tracked session; partial tracking would
    # show a misleading count, so fall through to silent eviction instead.
    if browser_request? && user.user_sessions.count >= user.tokens.size
      handle_sessions_limit_for_login(user)
      true
    else
      evict_oldest_session(user)
      false
    end
  end

  def browser_request?
    request.user_agent.to_s.include?('Mozilla')
  end

  def revoking_sessions?
    params[:revoke_session_id].present? || params[:revoke_all_sessions].present?
  end

  def revoke_sessions_for_login(user)
    if params[:revoke_all_sessions].present?
      user.tokens = {}
      user.save!
      user.user_sessions.destroy_all
    elsif params[:revoke_session_id].present?
      session = user.user_sessions.find_by(id: params[:revoke_session_id])
      return unless session

      user.tokens.delete(session.client_id)
      user.save!
      session.destroy!
    end
  end

  def evict_oldest_session(user)
    # Drop pre-rollout untracked tokens first so freshly tracked logins aren't evicted.
    return evict_oldest_token(user) if user.user_sessions.count < user.tokens.size

    oldest_session = user.user_sessions.order(Arel.sql('COALESCE(last_activity_at, created_at) ASC')).first
    return evict_oldest_token(user) unless oldest_session

    user.tokens.delete(oldest_session.client_id)
    user.save!
    oldest_session.destroy!
  end

  # Fallback if a token exists without a UserSession row (e.g., legacy data before tracking shipped).
  def evict_oldest_token(user)
    return if user.tokens.blank?

    oldest_client_id = user.tokens.min_by { |_, v| v['expiry'].to_i }&.first
    return unless oldest_client_id

    user.tokens.delete(oldest_client_id)
    user.save!
  end

  def handle_sessions_limit_for_login(user)
    sessions = user.user_sessions.order(last_activity_at: :desc).map { |s| s.slice(*PICKER_SESSION_FIELDS) }
    render json: { sessions_limit_reached: true, sessions: sessions }, status: :conflict
  end
end
