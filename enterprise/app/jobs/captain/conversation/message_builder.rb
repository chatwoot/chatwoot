module Captain::Conversation::MessageBuilder
  SOURCE_MARKER_PATTERN = /\[\[source:(\d+)\]\]/
  MALFORMED_SOURCE_MARKER_PATTERN = /\[\[source:[^\]\n]*\]\]?/
  CUSTOMER_CITATION_PATTERN = /\[\[(\d+)\]\([^\)\n]*\)\]/

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
    message_content = resolve_citations(@response['response'])
    validate_message_content!(message_content)
    create_outgoing_message(message_content, agent_name: @response['agent_name'])
  end

  def resolve_citations(content)
    return content if content.blank?

    citation_urls = trusted_citation_urls
    content = content.gsub(CUSTOMER_CITATION_PATTERN) do
      citation_for(Regexp.last_match(1), citation_urls)
    end
    content = content.gsub(SOURCE_MARKER_PATTERN) do
      citation_for(Regexp.last_match(1), citation_urls)
    end
    content.gsub(MALFORMED_SOURCE_MARKER_PATTERN, '')
  end

  def citation_for(source_number, citation_urls)
    url = citation_urls[source_number.to_s]
    return '' if url.blank?

    "[[#{source_number}](#{url})]"
  end

  def trusted_citation_urls
    return {} unless @assistant.config['feature_citation']

    source_map = citation_source_map
    return {} if source_map.empty?

    document_links = Captain::Document.where(
      id: source_map.values,
      account_id: account.id,
      assistant_id: @assistant.id
    ).pluck(:id, :external_link).to_h

    source_map.each_with_object({}) do |(source_number, document_id), urls|
      external_link = document_links[document_id]
      urls[source_number] = external_link if customer_safe_document_link?(external_link)
    end
  end

  def citation_source_map
    raw_citation_source_map.filter_map do |source_number, document_id|
      [source_number.to_s, document_id.to_i] if valid_citation_source?(source_number, document_id)
    end.to_h
  end

  def raw_citation_source_map
    context = @run_result&.context || {}
    state = context[:state] || context['state'] || {}
    state[:captain_v2_citation_source_map] || state['captain_v2_citation_source_map'] || {}
  end

  def valid_citation_source?(source_number, document_id)
    source_number.to_s.match?(/\A[1-9]\d*\z/) && document_id.to_s.match?(/\A\d+\z/)
  end

  def customer_safe_document_link?(external_link)
    external_link.present? && !external_link.start_with?('PDF:')
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
