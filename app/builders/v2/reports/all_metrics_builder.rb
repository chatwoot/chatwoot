class V2::Reports::AllMetricsBuilder
  attr_reader :account, :params

  def initialize(account, params = {})
    @account = account
    @params = params
  end

  def build
    conversations_scope.includes(
      :inbox,
      :contact,
      :team,
      :labels,
      :csat_survey_response,
      messages: [:sender],
      conversation_participants: [:user]
    ).find_each(batch_size: 100).map do |conversation|
      build_conversation_row(conversation)
    end
  end

  private

  def conversations_scope
    scope = account.conversations
    apply_conversation_filters(scope)
  end

  def apply_conversation_filters(scope)
    scope = apply_basic_filters(scope)
    scope = apply_time_filters(scope)
    apply_user_filter(scope)
  end

  def apply_basic_filters(scope)
    basic_filters = {
      inbox_id: params[:inbox_ids],
      team_id: params[:team_ids]
    }

    basic_filters.each do |column, value|
      scope = scope.where(column => value) if value.present?
    end

    scope
  end

  def apply_time_filters(scope)
    scope = scope.where('conversations.created_at >= ?', Time.zone.at(params[:since].to_i)) if params[:since].present?
    scope = scope.where('conversations.created_at <= ?', Time.zone.at(params[:until].to_i)) if params[:until].present?
    scope
  end

  def apply_user_filter(scope)
    return scope if params[:user_ids].blank?

    scope.joins(:messages)
         .where(messages: { sender_type: 'User', sender_id: params[:user_ids] })
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
      agents: participating_agents(conversation).map { |n| clean(n) }
    }
  end

  def extra_fields(conversation)
    {
      duration: conversation_duration(conversation),
      first_response_time: first_response_time(conversation),
      avg_response_time: avg_response_time(conversation),
      csat_score: conversation.csat_survey_response&.rating,
      csat_feedback: clean(conversation.csat_survey_response&.feedback_message),
      labels: conversation.cached_label_list_array.map { |l| clean(l) },
      custom_attributes: clean_hash(conversation.custom_attributes || {}),
      contact_additional_attributes: clean_hash(conversation.contact.additional_attributes || {}),
      contact_custom_attributes: clean_hash(conversation.contact.custom_attributes || {})
    }
  end

  def participating_agents(conversation)
    agent_ids = conversation.messages
                            .outgoing
                            .where(sender_type: 'User')
                            .pluck(:sender_id)
                            .uniq

    User.where(id: agent_ids).pluck(:name)
  end

  def conversation_duration(conversation)
    account.reporting_events
           .where(
             name: 'conversation_resolved',
             conversation_id: conversation.id
           )
           .average(average_value_key)
           &.round
  end

  def first_response_time(conversation)
    account.reporting_events
           .where(
             name: 'first_response',
             conversation_id: conversation.id
           )
           .average(average_value_key)
           &.round
  end

  def avg_response_time(conversation)
    account.reporting_events
           .where(
             name: 'reply_time',
             conversation_id: conversation.id
           )
           .average(average_value_key)
           &.round
  end

  def average_value_key
    ActiveModel::Type::Boolean.new.cast(params[:business_hours]).present? ? :value_in_business_hours : :value
  end

  def clean(value)
    return nil if value.nil?

    value.to_s.gsub('&quot;', '"').gsub('&amp;', '&').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&apos;', "'")
  end

  def clean_hash(value)
    return {} unless value.is_a?(Hash)

    value.transform_values { |v| clean_hash_value(v) }
  end

  def clean_hash_value(value)
    case value
    when String
      clean(value)
    when Hash
      clean_hash(value)
    when Array
      value.map { |v| v.is_a?(String) ? clean(v) : v }
    else
      value
    end
  end
end
