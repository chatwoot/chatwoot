class V2::Reports::BotMetricsBuilder
  include DateRangeHelper
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def metrics
    {
      conversation_count: bot_conversations.count,
      message_count: bot_messages.count,
      resolution_rate: bot_resolution_rate.to_i,
      handoff_rate: bot_handoff_rate.to_i
    }
  end

  private

  def selected_inbox_ids
    @selected_inbox_ids ||= params[:inbox_ids]&.reject(&:blank?)
  end

  def bot_conversations
    @bot_conversations ||= begin
      scope = account.conversations.where(created_at: range)
      scope = scope.where(inbox_id: selected_inbox_ids) if selected_inbox_ids.present?
      scope
    end
  end

  def bot_messages
    @bot_messages ||= account.messages
                             .outgoing
                             .where(conversation_id: bot_conversations.ids)
                             .where(created_at: range)
  end

  def bot_resolutions_count
    account.reporting_events
           .where(account_id: account.id, name: :conversation_bot_resolved, created_at: range)
           .filter_by_inbox_id(selected_inbox_ids)
           .select(:conversation_id)
           .distinct
           .count
  end

  def bot_handoffs_count
    account.reporting_events
           .where(account_id: account.id, name: :conversation_bot_handoff, created_at: range)
           .filter_by_inbox_id(selected_inbox_ids)
           .select(:conversation_id)
           .distinct
           .count
  end

  def bot_resolution_rate
    return 0 if bot_conversations.count.zero?

    bot_resolutions_count.to_f / bot_conversations.count * 100
  end

  def bot_handoff_rate
    return 0 if bot_conversations.count.zero?

    bot_handoffs_count.to_f / bot_conversations.count * 100
  end
end
