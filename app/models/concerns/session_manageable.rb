# Provides session management functionality for Devise Token Auth tokens.
# Handles logout operations, session limits, and token cleanup.
module SessionManageable
  extend ActiveSupport::Concern

  # Clears all active sessions for the user.
  # @return [void]
  def logout_all_sessions!
    self.tokens = {}
    save!
  end

  # Logs out a specific session by client ID.
  # @param client_id [String] the client identifier to logout
  # @return [Boolean] true if session was found and removed
  def logout_session!(client_id)
    return false unless client_id.present? && tokens.present?

    removed = tokens.delete(client_id)
    save! if removed

    removed.present?
  end

  # Removes tokens that expired before the given timestamp.
  # @param timestamp [Time, Integer] cutoff time for token cleanup
  # @return [void]
  def reset_tokens_before!(timestamp)
    return unless tokens.present?

    self.tokens = tokens.select do |_client_id, token_data|
      (token_data['expiry'] || 0) >= timestamp.to_i
    end

    save!
  end

  # Returns count of non-expired active sessions.
  # @return [Integer] number of active sessions
  def active_session_count
    return 0 unless tokens.present?

    current_time = Time.current.to_i
    tokens.count { |_client_id, token_data| (token_data['expiry'] || 0) > current_time }
  end

  # Checks if user has exceeded configured session limit.
  # @return [Boolean] true if session limit is exceeded
  def session_limit_exceeded?
    active_session_count >= session_limit
  end

  # Returns session information for all active tokens.
  # @return [Array<Hash>] array of session info, sorted by expiry (newest first)
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

  # Returns configured session limit from GlobalConfig.
  # Defaults to infinity if not configured.
  # @return [Integer, Float] session limit or Float::INFINITY
  def session_limit
    @session_limit ||= GlobalConfig.get(
      'USER_SESSION_LIMIT',
      'USER_SESSION_LIMIT_PER_USER',
      account: Current.account
    )&.to_i || Float::INFINITY
  end
end
