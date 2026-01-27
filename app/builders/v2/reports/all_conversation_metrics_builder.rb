require 'cgi'

class V2::Reports::AllConversationMetricsBuilder
  BATCH_SIZE = 500

  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
    @reporting_events_cache = {}
    @participating_agents_cache = {}
    @clean_cache = {}
  end

  def build
    result = []

    conversations_scope
      .includes(:inbox, :contact, :team, :csat_survey_response)
      .find_in_batches(batch_size: BATCH_SIZE) do |batch|
        preload_batch_data(batch.map(&:id))
        batch.each { |conversation| result << build_conversation_row(conversation) }
      end

    result
  end

  def build_streaming
    conversations_scope
      .includes(:inbox, :contact, :team, :csat_survey_response)
      .find_in_batches(batch_size: BATCH_SIZE) do |batch|
        preload_batch_data(batch.map(&:id))
        batch.each { |conversation| yield build_conversation_row(conversation) }
      end
  end

  private

  def preload_batch_data(conversation_ids)
    return if conversation_ids.empty?

    preload_reporting_events_batch(conversation_ids)
    preload_participating_agents_batch(conversation_ids)
  end

  def preload_reporting_events_batch(conversation_ids)
    events = account.reporting_events
                    .where(conversation_id: conversation_ids)
                    .where(name: %w[conversation_resolved first_response reply_time agent_chat_duration])
                    .select(:conversation_id, :name, average_value_key)
                    .group_by { |e| [e.conversation_id, e.name] }

    @reporting_events_cache.merge!(events)
  end

  def preload_participating_agents_batch(conversation_ids)
    participants = ConversationParticipant
                   .joins(:user)
                   .where(conversation_id: conversation_ids)
                   .pluck(:conversation_id, 'users.id', 'users.name')

    return if participants.empty?

    participants
      .group_by(&:first)
      .each do |conv_id, records|
        @participating_agents_cache[conv_id] = records.map(&:third).uniq.compact
      end
  end

  def conversations_scope
    @conversations_scope ||= begin
      scope = account.conversations
                     .select(:id, :display_id, :created_at, :inbox_id, :team_id,
                             :contact_id, :custom_attributes, :cached_label_list)
      scope = apply_basic_filters(scope)
      scope = apply_time_filters(scope)
      apply_user_filter(scope)
    end
  end

  def apply_basic_filters(scope)
    scope = scope.where(inbox_id: params[:inbox_ids]) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids])   if params[:team_ids].present?
    scope
  end

  def apply_time_filters(scope)
    scope = scope.where('conversations.created_at >= ?', Time.zone.at(params[:since].to_i)) if params[:since].present?
    scope = scope.where('conversations.created_at <= ?', Time.zone.at(params[:until].to_i)) if params[:until].present?
    scope
  end

  def apply_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope
      .joins(:conversation_participants)
      .where(conversation_participants: { user_id: params[:user_ids] })
      .distinct
  end

  def build_conversation_row(conversation)
    base_fields(conversation).merge(extra_fields(conversation))
  end

  def base_fields(conversation)
    {
      conversation_id: conversation.display_id,
      created_at: conversation.created_at,
      inbox_name: clean(conversation.inbox.name),
      team_name: clean(conversation.team&.name),
      contact_email: clean(conversation.contact.email),
      contact_name: clean(conversation.contact.name),
      agents: participating_agents(conversation)
    }
  end

  def extra_fields(conversation)
    csat = conversation.csat_survey_response

    {
      duration: conversation_duration(conversation),
      first_response_time: first_response_time(conversation),
      avg_response_time: avg_response_time(conversation),
      agent_chat_duration: agent_chat_duration(conversation),
      csat_score: csat&.rating,
      csat_feedback: csat ? clean(csat.feedback_message) : nil,
      labels: conversation.cached_label_list_array.map { |l| clean(l) },
      custom_attributes: clean_hash(conversation.custom_attributes || {}),
      contact_additional_attributes: clean_hash(conversation.contact.additional_attributes || {}),
      contact_custom_attributes: clean_hash(conversation.contact.custom_attributes || {})
    }
  end

  def participating_agents(conversation)
    @participating_agents_cache[conversation.id] || []
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

  def agent_chat_duration(conversation)
    reporting_sum_cached('agent_chat_duration', conversation.id)
  end

  def reporting_average_cached(event_name, conversation_id)
    events = @reporting_events_cache[[conversation_id, event_name]] || []
    return nil if events.empty?

    values = events.filter_map { |e| e.send(average_value_key) }
    return nil if values.empty?

    (values.sum.to_f / values.size).round
  end

  def reporting_sum_cached(event_name, conversation_id)
    events = @reporting_events_cache[[conversation_id, event_name]] || []
    return nil if events.empty?

    events.sum { |e| e.send(average_value_key) || 0 }.round
  end

  def average_value_key
    @average_value_key ||= ActiveModel::Type::Boolean.new.cast(params[:business_hours]) ? :value_in_business_hours : :value
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
