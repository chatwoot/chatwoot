class AutomationRules::TimerFilterService
  def initialize(conversation, query_hash)
    @conversation = conversation
    @key = query_hash['attribute_key']
    @value = query_hash['values'].map(&:to_i).max
    @operator = query_hash['query_operator']
    @last_human_message = @conversation.messages.human.last
  end

  def query_string
    return condition_query(passed: false) if @last_human_message.blank?

    passed = @value.positive? && awaiter_wait_since.before?(@value.minutes.ago)
    condition_query(passed: passed)
  end

  private

  def condition_query(passed: false)
    passed ? " TRUE #{@operator} " : " FALSE #{@operator} "
  end

  def agent_wait_since
    return Time.current if @last_human_message.incoming?

    @agent_wait_since ||= @conversation.messages.agent.maximum(:created_at) || Time.current
  end

  def contact_wait_since
    return Time.current if @last_human_message.outgoing?
    return @contact_wait_since if defined?(@contact_wait_since)

    last_outgoing_at = @conversation.messages.human.outgoing.maximum(:created_at) || @conversation.created_at
    @contact_wait_since = @conversation.messages.incoming.where(created_at: last_outgoing_at..).minimum(:created_at)
  end

  def awaiter_wait_since
    case @key
    when 'contact_wait_time'
      contact_wait_since
    when 'agent_wait_time'
      agent_wait_since
    else
      Time.current
    end
  end
end
