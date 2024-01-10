module Enterprise::Inbox
  def member_ids_with_assignment_capacity
    max_assignment_limit = auto_assignment_config['max_assignment_limit']
    overloaded_agent_ids = max_assignment_limit.present? ? get_agent_ids_over_assignment_limit(max_assignment_limit) : []
    super - overloaded_agent_ids
  end

  def get_responses(query)
    embedding = Openai::EmbeddingsService.new.get_embedding(query)
    responses.active.nearest_neighbors(:embedding, embedding, distance: 'cosine').first(5)
  end

  def active_bot?
    super || response_bot_enabled?
  end

  def response_bot_enabled?
    account.feature_enabled?('response_bot') && response_sources.any?
  end

  private

  def get_agent_ids_over_assignment_limit(limit)
    conversations.open.select(:assignee_id).group(:assignee_id).having("count(*) >= #{limit.to_i}").filter_map(&:assignee_id)
  end

  def ensure_valid_max_assignment_limit
    return if auto_assignment_config['max_assignment_limit'].blank?
    return if auto_assignment_config['max_assignment_limit'].to_i.positive?

    errors.add(:auto_assignment_config, 'max_assignment_limit must be greater than 0')
  end
end
