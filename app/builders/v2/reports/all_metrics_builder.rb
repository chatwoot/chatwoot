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
    scope = scope.where('conversations.created_at >= ?', Time.zone.at(params[:since].to_i)) if params[:since].present?
    scope = scope.where('conversations.created_at <= ?', Time.zone.at(params[:until].to_i)) if params[:until].present?
    scope = scope.where(inbox_id: params[:inbox_ids]) if params[:inbox_ids].present?
    scope = scope.where(team_id: params[:team_ids]) if params[:team_ids].present?

    if params[:user_ids].present?
      scope = scope.joins(:messages)
                   .where(messages: { sender_type: 'User', sender_id: params[:user_ids] })
                   .distinct
    end

    scope
  end

  def build_conversation_row(conversation)
    {
      conversation_id: conversation.display_id,
      created_at: conversation.created_at,
      inbox_name: clean(conversation.inbox.name),
      team_name: clean(conversation.team&.name),
      contact_email: clean(conversation.contact.email),
      contact_name: clean(conversation.contact.name),
      agents: participating_agents(conversation).map { |name| clean(name) },
      duration: conversation_duration(conversation),
      first_response_time: first_response_time(conversation),
      avg_response_time: avg_response_time(conversation),
      csat_score: conversation.csat_survey_response&.rating,
      csat_feedback: clean(conversation.csat_survey_response&.feedback_message),
      labels: conversation.cached_label_list_array.map { |label| clean(label) },
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
    return nil if conversation.status != 'resolved'

    (conversation.updated_at - conversation.created_at).to_i
  end

  def first_response_time(conversation)
    return nil if conversation.first_reply_created_at.blank?

    (conversation.first_reply_created_at - conversation.created_at).to_i
  end

  def avg_response_time(conversation)
    incoming_messages = conversation.messages.incoming.order(:created_at)
    return nil if incoming_messages.empty?

    outgoing_messages = conversation.messages
                                    .outgoing
                                    .where(sender_type: 'User')
                                    .where("(additional_attributes->'automation_rule_id') IS NULL")
                                    .where("(additional_attributes->'campaign_id') IS NULL")
                                    .order(:created_at)

    return nil if outgoing_messages.empty?

    response_times = []
    incoming_messages.each do |incoming|
      next_outgoing = outgoing_messages.find { |out| out.created_at > incoming.created_at }
      next unless next_outgoing

      response_times << (next_outgoing.created_at - incoming.created_at).to_i
    end

    return nil if response_times.empty?

    (response_times.sum.to_f / response_times.size).round
  end

  def clean(value)
    return nil if value.nil?

    value.to_s.gsub('&quot;', '"').gsub('&amp;', '&').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&apos;', "'")
  end

  def clean_hash(hash)
    return {} if hash.blank?

    hash.transform_values do |value|
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
end
