class Sla::EscalationJob < ApplicationJob
  queue_as :high

  def perform(conversation, breach_type, department_id = nil)
    @conversation = conversation
    @breach_type = breach_type
    @department = Department.find_by(id: department_id) if department_id

    escalate_conversation
    notify_supervisors
    update_conversation_priority
  end

  private

  def escalate_conversation
    # Reassign to most available supervisor or senior agent
    escalation_agent = find_escalation_agent
    
    if escalation_agent && escalation_agent != @conversation.assignee
      @conversation.update!(
        assignee: escalation_agent,
        priority: escalated_priority
      )

      # Create escalation message
      create_escalation_message(escalation_agent)
    end
  end

  def find_escalation_agent
    # First try to find supervisors in the department
    if @department
      supervisors = User.joins(:account_users)
                       .where(account_users: { 
                         account_id: @conversation.account_id, 
                         role: 'supervisor' 
                       })
      
      return supervisors.first if supervisors.any?
    end

    # Fall back to administrators
    User.joins(:account_users)
        .where(account_users: { 
          account_id: @conversation.account_id, 
          role: 'administrator' 
        })
        .first
  end

  def escalated_priority
    case @conversation.priority
    when 'low'
      'medium'
    when 'medium'
      'high'  
    when 'high', 'urgent'
      'urgent'
    else
      'high'
    end
  end

  def notify_supervisors
    supervisors = User.joins(:account_users)
                      .where(account_users: { 
                        account_id: @conversation.account_id, 
                        role: ['administrator', 'supervisor'] 
                      })

    supervisors.each do |supervisor|
      Enterprise::AgentNotifications::ConversationNotificationsMailer
        .sla_escalation_notification(@conversation, supervisor, @breach_type)
        .deliver_later
    end
  end

  def update_conversation_priority
    @conversation.update!(
      priority: escalated_priority,
      additional_attributes: @conversation.additional_attributes.merge({
        'sla_escalated' => true,
        'sla_escalation_reason' => @breach_type,
        'sla_escalated_at' => Time.current.iso8601
      })
    )
  end

  def create_escalation_message(escalation_agent)
    @conversation.messages.create!(
      account: @conversation.account,
      inbox: @conversation.inbox,
      message_type: 'activity',
      content: escalation_message_content(escalation_agent),
      sender: escalation_agent
    )
  end

  def escalation_message_content(escalation_agent)
    "🚨 **SLA Escalation** - This conversation has been escalated due to #{@breach_type.humanize.downcase} breach and reassigned to #{escalation_agent.name}. Priority updated to #{escalated_priority.upcase}."
  end
end