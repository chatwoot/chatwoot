class Conversations::AssignmentService
  def initialize(conversation:, assignee_id:, assignee_type: nil)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
  end

  def perform
    # #region agent log
    debug_assignee_log(
      'assignment_service perform start',
      {
        conversation_id: conversation.id,
        assignee_id: conversation.assignee_id,
        assignee_agent_bot_id: conversation.assignee_agent_bot_id,
        requested_assignee_id: assignee_id,
        requested_assignee_type: assignee_type
      },
      'A'
    )
    # #endregion
    result = agent_bot_assignment? ? assign_agent_bot : assign_agent
    conversation.reload
    # #region agent log
    debug_assignee_log(
      'assignment_service perform end',
      {
        conversation_id: conversation.id,
        assignee_id: conversation.assignee_id,
        assignee_agent_bot_id: conversation.assignee_agent_bot_id,
        assignee_type: conversation.assignee_type,
        result_class: result.class.name
      },
      'A'
    )
    # #endregion
    result
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type

  def assign_agent
    if cleared_assignee? && (bot = conversation.inbox.assignable_agent_bot)
      return assign_inbox_bot(bot)
    end

    conversation.assignee = assignee
    conversation.assignee_agent_bot = nil
    conversation.save!
    assignee
  end

  def cleared_assignee?
    assignee_id.blank? || assignee_id.to_i.zero?
  end

  def assign_inbox_bot(bot)
    conversation.assignee = nil
    conversation.assignee_agent_bot = bot
    conversation.save!
    bot
  end

  def assign_agent_bot
    return unless agent_bot

    conversation.assignee = nil
    conversation.assignee_agent_bot = agent_bot
    conversation.save!
    agent_bot
  end

  def assignee
    @assignee ||= conversation.account.users.find_by(id: assignee_id)
  end

  def agent_bot
    @agent_bot ||= AgentBot.accessible_to(conversation.account).find_by(id: assignee_id)
  end

  def agent_bot_assignment?
    assignee_type.to_s == 'AgentBot'
  end

  def debug_assignee_log(message, data, hypothesis_id)
    payload = {
      sessionId: 'b893f4',
      hypothesisId: hypothesis_id,
      location: 'assignment_service.rb',
      message: message,
      data: data,
      timestamp: (Time.now.to_f * 1000).to_i
    }
    File.open(Rails.root.join('debug-b893f4.log'), 'a') { |f| f.puts(payload.to_json) }
  rescue StandardError
    nil
  end
end
