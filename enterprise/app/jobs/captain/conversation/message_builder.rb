module Captain::Conversation::MessageBuilder
  private

  def create_messages
    response_parts = Captain::Assistant::ResponseParts.from_response(@response)
    citation_urls = @assistant.trusted_citation_urls(@run_result)
    message_content = response_parts.customer_message_content(citation_urls: citation_urls)
    validate_message_content!(message_content)
    create_outgoing_message(message_content, agent_name: @response['agent_name'], response_parts: response_parts.to_a)
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
