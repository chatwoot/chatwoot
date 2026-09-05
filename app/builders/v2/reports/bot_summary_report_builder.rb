class V2::Reports::BotSummaryReportBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    load_data
    prepare_report
  end

  private

  attr_reader :conversations_count, :resolved_count,
              :avg_resolution_time, :avg_first_response_time, :avg_reply_time,
              :bot_chat_duration, :bot_handoffs_count

  def load_data
    @conversations_count = fetch_conversations_count
    @bot_handoffs_count = fetch_bot_handoffs_count
    load_reporting_events_data
  end

  def fetch_conversations_count
    inbox_ids = AgentBotInbox
                .where(account_id: account.id, status: :active)
                .pluck(:inbox_id, :agent_bot_id)

    if params[:inbox_ids]&.reject(&:blank?).present?
      allowed = params[:inbox_ids].map(&:to_i)
      inbox_ids = inbox_ids.slice(*allowed)
    end

    return {} if inbox_ids.empty?

    inbox_to_bot = inbox_ids.to_h

    account.conversations
           .where(created_at: range)
           .where(inbox_id: inbox_to_bot.keys)
           .group(:inbox_id)
           .count
           .each_with_object(Hash.new(0)) do |(inbox_id, count), result|
             bot_id = inbox_to_bot[inbox_id]
             result[bot_id] += count
           end
  end

  def fetch_bot_handoffs_count
    account.reporting_events
           .where(name: 'conversation_bot_handoff', created_at: range)
           .filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?))
           .group(:agent_bot_id)
           .distinct
           .count(:conversation_id)
  end

  def load_reporting_events_data
    index_key = group_by_key.to_s.split('.').last
    results = reporting_events
              .select(
                "#{group_by_key} as #{index_key}",
                "COUNT(CASE WHEN name = 'conversation_bot_resolved' THEN 1 END) as resolved_count",
                "AVG(CASE WHEN name = 'conversation_bot_resolved' THEN #{average_value_key} END) as avg_resolution_time",
                "AVG(CASE WHEN name = 'bot_first_response' THEN #{average_value_key} END) as avg_first_response_time",
                "AVG(CASE WHEN name = 'bot_reply_time' THEN #{average_value_key} END) as avg_reply_time"
              )
              .group(group_by_key)
              .index_by { |record| record.public_send(index_key) }

    @resolved_count = results.transform_values(&:resolved_count)
    @avg_resolution_time = results.transform_values(&:avg_resolution_time)
    @avg_first_response_time = results.transform_values(&:avg_first_response_time)
    @avg_reply_time = results.transform_values(&:avg_reply_time)
  end

  def prepare_report
    account.agent_bots.map do |bot|
      build_bot_stats(bot)
    end
  end

  def build_bot_stats(bot)
    bot_id = bot.id
    {
      id: bot_id,
      name: bot.name,
      conversations_count: conversations_count[bot_id] || 0,
      resolved_conversations_count: resolved_count[bot_id] || 0,
      handoffs_count: bot_handoffs_count[bot_id] || 0,
      avg_first_response_time: avg_first_response_time[bot_id],
      avg_reply_time: avg_reply_time[bot_id],
      avg_resolution_time: avg_resolution_time[bot_id]
    }
  end

  def group_by_key
    :agent_bot_id
  end

  def reporting_events
    account.reporting_events
           .where(created_at: range)
           .where.not(agent_bot_id: nil)
           .filter_by_inbox_id(params[:inbox_ids]&.reject(&:blank?))
  end
end
