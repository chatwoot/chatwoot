# frozen_string_literal: true

# Listener for Aloo AI Agent events
# Triggers AI responses and learning jobs based on conversation events
class AlooAgentListener < BaseListener
  # Triggered when a new message is created
  # Initiates AI response for incoming messages (text or voice)
  def message_created(event)
    message, _account = extract_message_and_account(event)

    # Check for audio attachments first (voice messages)
    audio_attachment = find_audio_attachment(message)
    if audio_attachment.present?
      return unless should_transcribe_audio?(message)

      # Trigger transcription job (chains to ResponseJob on success)
      Aloo::AudioTranscriptionJob.perform_later(audio_attachment.id)
      return
    end

    # Handle regular text messages
    return unless should_respond_to_message?(message)

    # Queue the AI response job
    Aloo::ResponseJob.perform_later(message.conversation_id, message.id)
  end

  # Triggered when a conversation is resolved
  # Initiates memory extraction and FAQ generation
  def conversation_resolved(event)
    conversation, = extract_conversation_and_account(event)

    assistant = conversation.inbox.aloo_assistant
    return unless assistant&.active?

    # Queue memory extraction if enabled
    Aloo::ExtractMemoriesJob.perform_later(conversation.id) if assistant.feature_memory_enabled?

    # Queue FAQ generation if enabled
    return unless assistant.feature_faq_enabled?

    Aloo::FaqGeneratorJob.perform_later(conversation.id)
  end

  # Triggered when a conversation status changes
  # Clears handoff flag when conversation is reopened
  def conversation_status_changed(event)
    conversation = event.data[:conversation]
    changed_attributes = event.data[:changed_attributes]

    return unless changed_attributes&.key?('status')

    changed_attributes['status'][0]
    current_status = changed_attributes['status'][1]

    # If reopened from handoff, reset the handoff flag
    return unless current_status == 'open' && conversation.custom_attributes&.dig('aloo_handoff_active')

    clear_handoff_flag(conversation)
  end

  private

  def should_respond_to_message?(message)
    # Only respond to incoming messages
    return false unless message.incoming?

    # Don't respond to private messages
    return false if message.private?

    # Must be a text message (not attachments only)
    return false if message.content.blank?

    # Check if inbox has an active Aloo assistant
    assistant = message.inbox.aloo_assistant
    return false unless assistant&.active?

    # Check if handoff is active
    conversation = message.conversation
    return false if conversation.custom_attributes&.dig('aloo_handoff_active')

    # Check if conversation has a human assignee (don't interrupt)
    return false if conversation.assignee.present? && !assignee_is_bot?(conversation)

    true
  end

  def assignee_is_bot?(_conversation)
    # Check if the assignee is the aloo assistant (not a human)
    # For now, we don't assign aloo to conversations, so any assignee means human
    false
  end

  def clear_handoff_flag(conversation)
    attrs = conversation.custom_attributes.dup
    attrs['aloo_handoff_active'] = false
    attrs['aloo_handoff_cleared_at'] = Time.current.iso8601
    conversation.update!(custom_attributes: attrs)
  end

  def find_audio_attachment(message)
    message.attachments.find { |a| a.file_type == 'audio' }
  end

  def should_transcribe_audio?(message)
    return false unless message.incoming?
    return false if message.private?

    assistant = message.inbox.aloo_assistant
    return false unless assistant&.active?
    return false unless assistant.voice_transcription_enabled?

    conversation = message.conversation
    return false if conversation.custom_attributes&.dig('aloo_handoff_active')
    return false if conversation.assignee.present? && !assignee_is_bot?(conversation)

    true
  end
end
