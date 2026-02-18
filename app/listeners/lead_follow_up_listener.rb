class LeadFollowUpListener < BaseListener
  # Evento cuando se crea un mensaje (contact o agent)
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation
    follow_up = conversation.conversation_follow_up

    return unless follow_up&.status == 'active'

    sequence = follow_up.lead_follow_up_sequence
    return unless sequence.active?

    if message.incoming?
      # Condición 1: Stop when contact replies
      handle_contact_reply(follow_up, sequence, message)
    elsif message.outgoing? && message.sender.is_a?(User)
      # Condición 4: Stop when agent replies
      handle_agent_reply(follow_up, sequence, message)
    end
  end

  # Evento cuando se actualiza una conversación (assignee, status, etc)
  def conversation_updated(event)
    conversation = event.data[:conversation]
    changes = event.data[:changed_attributes] || {}
    follow_up = conversation.conversation_follow_up

    return unless follow_up&.status == 'active'

    sequence = follow_up.lead_follow_up_sequence
    return unless sequence.active?

    # Condición 3: Stop when agent is assigned
    if changes.key?('assignee_id')
      handle_agent_assigned(follow_up, sequence, conversation, changes)
    end

    # Condición 2: Stop when conversation is resolved
    if changes.key?('status') && conversation.resolved?
      handle_conversation_resolved(follow_up, sequence, conversation)
    end
  end

  private

  # Condición 1: Contact replied
  def handle_contact_reply(follow_up, sequence, message)
    return unless sequence.settings.dig('stop_on_contact_reply')

    stop_copilot(
      follow_up: follow_up,
      reason: 'Contact replied',
      metadata: {
        message_id: message.id,
        message_content: message.content&.truncate(100)
      }
    )
  end

  # Condición 2: Conversation resolved
  def handle_conversation_resolved(follow_up, sequence, conversation)
    return unless sequence.settings.dig('stop_on_conversation_resolved')

    stop_copilot(
      follow_up: follow_up,
      reason: 'Conversation resolved',
      metadata: {
        resolved_at: conversation.updated_at,
        previous_status: conversation.status_before_last_save
      }
    )
  end

  # Condición 3: Agent assigned
  def handle_agent_assigned(follow_up, sequence, conversation, changes)
    return unless sequence.settings.dig('stop_on_agent_assigned')

    previous_assignee_id = changes['assignee_id'].first
    current_assignee = conversation.assignee

    # Solo detener si se asignó un agente (no si se desasignó o cambió entre agentes)
    return unless current_assignee.present?
    return if previous_assignee_id.present? # Ya tenía un agente asignado

    stop_copilot(
      follow_up: follow_up,
      reason: "Agent assigned: #{current_assignee.name}",
      metadata: {
        agent_id: current_assignee.id,
        agent_name: current_assignee.name,
        assigned_at: Time.current
      }
    )
  end

  # Condición 4: Agent replied
  def handle_agent_reply(follow_up, sequence, message)
    return unless sequence.settings.dig('stop_on_agent_reply')

    # Verificar que el mensaje fue creado después de la última acción del copilot
    return unless message.created_at > follow_up.updated_at

    agent = message.sender

    stop_copilot(
      follow_up: follow_up,
      reason: "Agent replied: #{agent.name}",
      metadata: {
        agent_id: agent.id,
        agent_name: agent.name,
        message_id: message.id,
        message_content: message.content&.truncate(100)
      }
    )
  end

  # Método centralizado para detener el follow-up de UNA conversación específica
  # NOTA: Esto NO detiene el copilot completo, solo detiene la ejecución para esta conversación
  def stop_copilot(follow_up:, reason:, metadata: {})
    conversation_id = follow_up.conversation_id
    enrollment = follow_up.sequence_enrollment

    follow_up.cancel_job!
    follow_up.mark_as_completed!(reason)

    if enrollment
      enrollment.update!(current_step: follow_up.current_step)
      enrollment.complete!(reason)
    end

    Rails.logger.info "Follow-up stopped for conversation #{conversation_id} (follow_up #{follow_up.id}): #{reason}"
  end
end
