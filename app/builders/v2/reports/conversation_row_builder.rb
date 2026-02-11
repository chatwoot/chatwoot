require 'cgi'

class V2::Reports::ConversationRowBuilder
  attr_reader :preloader, :clean_cache

  def initialize(preloader)
    @preloader = preloader
    @clean_cache = {}
  end

  def build_row(conversation)
    base_fields(conversation).merge(extra_fields(conversation))
  end

  private

  def base_fields(conversation)
    {
      conversation_id: conversation.display_id,
      created_at: conversation.created_at,
      inbox_name: clean(conversation.inbox.name),
      team_name: clean(conversation.team&.name),
      contact_email: clean(conversation.contact.email),
      contact_name: clean(conversation.contact.name),
      agents: participating_agents_names(conversation),
      agent_chat_durations: agent_chat_durations_by_agent(conversation)
    }
  end

  def extra_fields(conversation)
    csat = conversation.csat_survey_response

    {
      chat_resolution: conversation_duration(conversation),
      first_response_time: first_response_time(conversation),
      avg_response_time: avg_response_time(conversation),
      agent_chat_duration: total_agent_chat_duration(conversation),
      csat_score: csat&.rating,
      csat_feedback: csat ? clean(csat.feedback_message) : nil,
      labels: conversation.cached_label_list_array.map { |l| clean(l) },
      custom_attributes: clean_hash(conversation.custom_attributes || {}),
      contact_additional_attributes: clean_hash(conversation.contact.additional_attributes || {}),
      contact_custom_attributes: clean_hash(conversation.contact.custom_attributes || {})
    }
  end

  def participating_agents_names(conversation)
    agents = preloader.participating_agents_cache[conversation.id] || []
    agents.map { |a| a[:name] || "User #{a[:id]}" }
  end

  def agent_chat_durations_by_agent(conversation)
    agents = preloader.participating_agents_cache[conversation.id] || []
    agents.map do |agent|
      agent_chat_duration_for_user(conversation.id, agent[:id])
    end
  end

  def agent_chat_duration_for_user(conversation_id, user_id)
    events = preloader.agent_chat_durations_cache[[conversation_id, user_id]] || []
    return nil if events.empty?

    events.sum { |e| e.send(average_value_key) || 0 }.round
  end

  def total_agent_chat_duration(conversation)
    total = preloader.agent_chat_durations_cache.select { |key, _| key[0] == conversation.id }.values
                     .flatten.sum { |event| event.send(average_value_key) || 0 }.round

    total.positive? ? total : nil
  end

  def conversation_duration(conversation)
    reporting_average_cached('conversation_resolved', conversation.id)
  end

  def first_response_time(conversation)
    reporting_average_cached('first_response', conversation.id)
  end

  def avg_response_time(conversation)
    reporting_average_cached('reply_time', conversation.id)
  end

  def reporting_average_cached(event_name, conversation_id)
    events = preloader.reporting_events_cache[[conversation_id, event_name]] || []
    return nil if events.empty?

    values = events.filter_map { |e| e.send(average_value_key) }
    return nil if values.empty?

    (values.sum.to_f / values.size).round
  end

  def average_value_key
    preloader.send(:average_value_key)
  end

  def clean(value)
    return nil if value.nil?

    key = value.to_s
    @clean_cache[key] ||= CGI.unescapeHTML(key)
  end

  def clean_hash(value)
    return {} unless value.is_a?(Hash)

    value.transform_values { |v| clean_hash_value(v) }
  end

  def clean_hash_value(value)
    case value
    when String then clean(value)
    when Hash   then clean_hash(value)
    when Array  then value.map { |v| v.is_a?(String) ? clean(v) : v }
    else value
    end
  end
end
