module Enterprise::Account
  def usage_limits
    {
      agents: agent_limits.to_i,
      inboxes: get_limits(:inboxes).to_i
    }
  end

  private

  def agent_limits
    custom_attributes['subscribed_quantity'] || get_limits(:agents)
  end

  def get_limits(limit_name)
    return increase_usage(limit_name) if limit_exceeded?(limit_name)

    # return self[:limits][limit_name.to_s] if self[:limits][limit_name.to_s].present?

    fetch_limit_from_config(limit_name) || ChatwootApp.max_limit
  end

  def limit_exceeded?(limit_name)
    product.present? &&
      product.details[name_of(limit_name)].present? &&
      send(limit_name).count > product.details[name_of(limit_name)]
  end

  def fetch_limit_from_config(limit_name)
    config_name = "ACCOUNT_#{limit_name.to_s.upcase}_LIMIT"
    config_value = GlobalConfig.get(config_name)[config_name]
    config_value.presence
  end

  def name_of(limit_name)
    "number_of_#{limit_name.to_s.pluralize.downcase}"
  end

  def extra_conversations
    account_plan&.extra_conversations || 0
  end

  def extra_agents
    account_plan&.extra_agents || 0
  end

  def increase_usage(limit_name)
    case limit_name
    when :conversations
      account_plan.update(extra_conversations: extra_conversations + 1)
    when :agents
      account_plan.update(extra_agents: extra_agents + 1)
    end
  end
end
