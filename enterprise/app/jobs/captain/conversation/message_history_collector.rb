module Captain::Conversation::MessageHistoryCollector
  private

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .flat_map { |message| history_entries_for_message(message) }
  end

  def history_entries_for_message(message)
    captain_run_context = message.captain_run_context if captain_v2_enabled? && message.outgoing?
    return captain_run_context['messages'] if captain_run_context&.dig('messages').present?

    [legacy_history_entry_for_message(message)]
  end

  def legacy_history_entry_for_message(message)
    message_hash = {
      content: prepare_multimodal_message_content(message),
      role: determine_role(message)
    }

    agent_name = message.additional_attributes&.dig('captain', 'agent', 'name') || message.additional_attributes&.dig('agent_name')
    message_hash[:agent_name] = agent_name if agent_name.present?

    message_hash
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end
end
