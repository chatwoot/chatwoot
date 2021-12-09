module Enterprise::Account
  def usage_limits
    {
      agents: get_limits(:agents),
      inboxes: get_limits(:inboxes)
    }
  end

  private

  def get_limits(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    self[:limits][limit_name.to_s] || GlobalConfig.get(config_name)[config_name] || ChatwootApp.max_limit
  end
end
