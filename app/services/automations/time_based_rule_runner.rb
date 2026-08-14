# frozen_string_literal: true

class Automations::TimeBasedRuleRunner
  LEDGER_TTL = 90.days.to_i
  RELATIVE_TO_VALUES = %w[after on before].freeze

  def initialize(rule)
    @rule = rule
    @account = rule.account
    @schedule = (@rule.schedule || {}).with_indifferent_access
  end

  def perform
    return if @schedule[:kind].blank?

    # Conditions first, then claim: a failed condition must not burn the Redis ledger window.
    candidates.find_each(batch_size: 50) do |conversation|
      next unless conditions_match?(conversation)
      next unless claim_window!(conversation)

      AutomationRules::ActionService.new(@rule, @account, conversation).perform
    end
  end

  private

  def candidates
    scope = @account.conversations
    case @schedule[:kind].to_s
    when 'days_since_attribute'
      days_since_attribute_scope(scope)
    when 'hours_since_last_outgoing'
      hours_since_last_message_scope(scope, :outgoing)
    when 'hours_since_last_incoming'
      hours_since_last_message_scope(scope, :incoming)
    else
      Conversation.none
    end
  end

  def days_since_attribute_scope(scope)
    key = @schedule[:attribute_key].to_s
    return Conversation.none if key.blank?

    relative = relative_to
    days = @schedule[:days].to_i
    return Conversation.none if relative != 'on' && days <= 0

    target_date = date_offset_target(relative, days)
    operator = relative == 'after' ? '<=' : '='

    # Only cast ISO YYYY-MM-DD (or datetime starting with that, e.g.
    # 2026-07-27T15:30:00Z). Invalid strings like "foo" must not raise —
    # they would abort the whole scheduler job. Datetime values use the
    # calendar date portion (LEFT 10) so offsets stay day-based.
    casted = <<~SQL.squish
      CASE
        WHEN (conversations.custom_attributes ->> ?) ~ '^\\d{4}-\\d{2}-\\d{2}'
        THEN LEFT(conversations.custom_attributes ->> ?, 10)::date
        ELSE NULL
      END
    SQL

    scope.where("#{casted} IS NOT NULL", key, key)
         .where("#{casted} #{operator} ?", key, key, target_date)
  end

  def relative_to
    value = @schedule[:relative_to].to_s.presence || 'after'
    RELATIVE_TO_VALUES.include?(value) ? value : 'after'
  end

  def date_offset_target(relative, days)
    today = Time.zone.today
    case relative
    when 'on'
      today
    when 'before'
      today + days
    else
      today - days
    end
  end

  def hours_since_last_message_scope(scope, message_type)
    hours = @schedule[:hours].to_i
    return Conversation.none if hours <= 0

    cutoff = hours.hours.ago
    type_value = Message.message_types[message_type.to_s]
    return Conversation.none if type_value.nil?

    # Latest non-activity, non-private message is of the given type and older than N hours.
    # Message has default_scope order(created_at: :asc) — must unscope or DISTINCT ON breaks.
    latest = Message
             .unscoped
             .select('DISTINCT ON (conversation_id) conversation_id, id, message_type, created_at')
             .where(account_id: @account.id)
             .where(private: false)
             .where.not(message_type: Message.message_types[:activity])
             .order('conversation_id, created_at DESC')

    # Select message id/created_at so window_id matches this same row (not last_activity_at).
    scope.joins("INNER JOIN (#{latest.to_sql}) latest_messages ON latest_messages.conversation_id = conversations.id")
         .where(latest_messages: { message_type: type_value })
         .where('latest_messages.created_at <= ?', cutoff)
         .select(
           'conversations.*, latest_messages.id AS time_rule_message_id, ' \
           'latest_messages.created_at AS time_rule_message_at'
         )
  end

  def conditions_match?(conversation)
    return true if @rule.conditions.blank?

    AutomationRules::ConditionsFilterService.new(@rule, conversation).perform
  end

  def claim_window!(conversation)
    key = format(
      ::Redis::Alfred::AUTOMATION_TIME_RULE_LEDGER,
      rule_id: @rule.id,
      conversation_id: conversation.id,
      window: window_id(conversation)
    )
    ::Redis::Alfred.set(key, Time.now.utc.to_i, nx: true, ex: LEDGER_TTL)
  end

  def window_id(conversation)
    case @schedule[:kind].to_s
    when 'days_since_attribute'
      raw = conversation.custom_attributes[@schedule[:attribute_key].to_s]
      "days:#{raw}:#{@schedule[:days]}:#{relative_to}"
    when 'hours_since_last_outgoing', 'hours_since_last_incoming'
      msg_id = conversation.read_attribute(:time_rule_message_id)
      msg_at = conversation.read_attribute(:time_rule_message_at)
      at_i = msg_at.respond_to?(:to_i) ? msg_at.to_i : nil
      "hours:#{@schedule[:hours]}:#{msg_id}:#{at_i}"
    else
      'default'
    end
  end
end
