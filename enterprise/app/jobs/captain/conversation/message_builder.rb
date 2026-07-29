module Captain::Conversation::MessageBuilder
  MODEL_CITATION_PATTERN = /\[\[faq:(\d+)\]\]/

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
    message_content = resolve_v2_citations(@response['response'])
    validate_message_content!(message_content)
    create_outgoing_message(message_content, agent_name: @response['agent_name'])
  end

  def resolve_v2_citations(content)
    return content unless captain_v2_enabled? && @assistant.config['feature_citation']
    return content if content.blank?

    citation_urls = trusted_citation_urls
    content.gsub(MODEL_CITATION_PATTERN) do
      index = Regexp.last_match(1)
      url = citation_urls[index]
      url.present? ? "[[#{index}](#{url})]" : ''
    end
  end

  def trusted_citation_urls
    sources = @run_result&.context&.dig(:state, :captain_v2_citation_sources) || {}
    responses = @assistant.responses.where(id: sources.values).includes(:documentable).index_by(&:id)

    sources.transform_values do |response_id|
      responses[response_id.to_i]&.customer_visible_source_url
    end.compact.transform_keys(&:to_s)
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content, agent_name: nil, preserve_waiting_since: false)
    additional_attrs = {}
    additional_attrs[:agent_name] = agent_name if agent_name.present?

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
