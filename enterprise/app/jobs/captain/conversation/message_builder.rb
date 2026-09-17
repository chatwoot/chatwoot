module Captain::Conversation::MessageBuilder
  private

  def collect_previous_messages
    @conversation
      .messages
      .where(message_type: [:incoming, :outgoing])
      .where(private: false)
      .map do |message|
      message_hash = {
        content: prepare_multimodal_message_content(message),
        role: determine_role(message)
      }

      # Include agent_name if present in additional_attributes
      message_hash[:agent_name] = message.additional_attributes['agent_name'] if message.additional_attributes&.dig('agent_name').present?

      message_hash
    end
  end

  def determine_role(message)
    message.message_type == 'incoming' ? 'user' : 'assistant'
  end

  def prepare_multimodal_message_content(message)
    Captain::OpenAiMessageBuilderService.new(message: message).generate_content
  end

  def create_messages
    return create_v1_message unless captain_v2_enabled?

    response_parts = Captain::Assistant::ResponseParts.from_response(@response)
    citation_urls = @assistant.trusted_citation_urls(@run_result)
    message_content = response_parts.customer_message_content(citation_urls: citation_urls)
    validate_message_content!(message_content)
    create_outgoing_message(message_content, agent_name: @response['agent_name'], response_parts: response_parts.to_a)
  end

  def create_v1_message
    validate_message_content!(@response['response'])
    create_outgoing_message(@response['response'], agent_name: @response['agent_name'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content, agent_name: nil, response_parts: nil, preserve_waiting_since: false)
    additional_attrs = {}
    additional_attrs[:agent_name] = agent_name if agent_name.present?
    additional_attrs[Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY] = response_parts unless response_parts.nil?

    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: message_content,
      additional_attributes: additional_attrs,
      preserve_waiting_since: preserve_waiting_since
    )
  end
end
