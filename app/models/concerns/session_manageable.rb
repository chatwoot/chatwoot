module SessionManageable
  extend ActiveSupport::Concern

  def logout_all_sessions!
    # Clear all devise token auth tokens
    self.tokens = {}
    save!
  end

  def logout_session!(client_id)
    return false unless client_id.present? && tokens.present?

    # Remove specific client token
    removed = tokens.delete(client_id)
    save! if removed

    removed.present?
  end

  def reset_tokens_before!(timestamp)
    return unless tokens.present?

    # Remove tokens that expired before the given timestamp
    self.tokens = tokens.select do |_client_id, token_data|
      (token_data['expiry'] || 0) >= timestamp.to_i
    end

    save!
  end

  def active_session_count
    return 0 unless tokens.present?

    # Count only non-expired tokens
    current_time = Time.current.to_i
    tokens.count { |_client_id, token_data| (token_data['expiry'] || 0) > current_time }
  end

  def session_limit_exceeded?
    active_session_count >= session_limit
  end

  def session_info
    return [] unless tokens.present?

    tokens.map do |client_id, token_data|
      {
        client_id: client_id,
        expiry: Time.zone.at(token_data['expiry'] || 0)
      }
    end.sort_by { |session| session[:expiry] }.reverse
  end

  private

  def session_limit
    @session_limit ||= GlobalConfig.get(
      'USER_SESSION_LIMIT',
      'USER_SESSION_LIMIT_PER_USER',
      account: Current.account
    )&.to_i || Float::INFINITY
  end
end
