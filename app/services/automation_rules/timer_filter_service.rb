class AutomationRules::TimerFilterService
  def initialize(conversation, query_hash)
    @conversation = conversation
    @key = query_hash['attribute_key']
    @value = query_hash['values'].map(&:to_i).max
    @operator = query_hash['query_operator']
  end

  def query_string
    passed = @value.positive? && awaiter_wait_since.before?(@value.minutes.ago)
    condition_query(passed: passed)
  end

  private

  def condition_query(passed: false)
    passed ? " #{@operator} TRUE" : " #{@operator} FALSE"
  end

  def agent_wait_since
    @agent_wait_since ||= @conversation.messages.agent.maximum(:created_at) || @conversation.created_at
  end

  def contact_wait_since
    @conversation.messages.incoming.where(created_at: agent_wait_since..).minimum(:created_at) || @conversation.created_at
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
