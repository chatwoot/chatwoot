class WorkflowListener < BaseListener
  def conversation_updated(event)
    process_event(event, 'conversation_updated')
  end

  def conversation_created(event)
    process_event(event, 'conversation_created')
  end

  def conversation_opened(event)
    process_event(event, 'conversation_opened')
  end

  def conversation_resolved(event)
    process_event(event, 'conversation_resolved')
  end

  def message_created(event)
    message = event.data[:message]

    return if ignore_message_created_event?(event)

    account = message.try(:account)
    return unless account
    
    workflows = current_account_workflows('message_created', account)
    
    workflows.each do |workflow|
      ::Workflows::ExecutionService.new(
        workflow: workflow,
        event_name: 'message_created',
        event_data: { message: message, changed_attributes: event.data[:changed_attributes] }
      ).perform
    end
  end

  private

  def process_event(event, event_name)
    return if performed_by_automation?(event)

    conversation = event.data[:conversation]
    account = conversation.account
    return unless account

    workflows = current_account_workflows(event_name, account)

    workflows.each do |workflow|
      ::Workflows::ExecutionService.new(
        workflow: workflow,
        event_name: event_name,
        event_data: { conversation: conversation, changed_attributes: event.data[:changed_attributes] }
      ).perform
    end
  end

  def current_account_workflows(event_name, account)
    Workflow.where(
      trigger_event: event_name,
      account_id: account.id,
      active: true
    )
  end

  def performed_by_automation?(event)
    event.data[:performed_by].present? && (event.data[:performed_by].instance_of?(AutomationRule) || event.data[:performed_by].instance_of?(Workflow))
  end

  def ignore_message_created_event?(event)
    message = event.data[:message]
    performed_by_automation?(event) || message.activity? || message.auto_reply_email?
  end
end
