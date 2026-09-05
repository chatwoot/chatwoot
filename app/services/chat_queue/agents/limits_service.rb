class ChatQueue::Agents::LimitsService
  pattr_initialize [:account!]

  def limit_for(agent_id)
    Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] Fetching limits")

    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
      limit = account_user.active_chat_limit.to_i
      Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] User limit=#{limit}")
      return limit
    end

    if account.active_chat_limit_enabled? && account.active_chat_limit_value.present?
      limit = account.active_chat_limit_value.to_i
      Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] Account limit=#{limit}")
      return limit
    end

    Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] No limits")
    nil
  end
end
