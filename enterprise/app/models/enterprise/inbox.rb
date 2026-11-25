module Enterprise::Inbox
  def member_ids_with_assignment_capacity
    return filter_by_capacity(available_agents).map(&:user_id) if enable_auto_assignment? && auto_assignment_v2_enabled?

    super
  end

  def active_bot?
    super || captain_active?
  end

  def captain_active?
    captain_assistant.present? && more_responses?
  end

  def conflicting_bot_provider(provider)
    super || ('Captain' if provider != :captain && CaptainInbox.joins(:captain_assistant).exists?(inbox_id: id))
  end

  private

  def more_responses?
    account.usage_limits[:captain][:responses][:current_available].positive?
  end
end
