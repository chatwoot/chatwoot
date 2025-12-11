# frozen_string_literal: true

module Integrations::LlmInstrumentationHelpers
  include Integrations::LlmInstrumentationConstants
  include Integrations::LlmInstrumentationCompletionHelpers

  def determine_provider(model_name)
    return 'openai' if model_name.blank?

    model = model_name.to_s.downcase

    LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end

    'openai'
  end

  private

  def setup_span_attributes(span, params)
    set_request_attributes(span, params)
    set_prompt_messages(span, params[:messages])
    set_metadata_attributes(span, params)
  end

  def record_completion(span, result)
    if result.respond_to?(:content)
      span.set_attribute(ATTR_GEN_AI_COMPLETION_ROLE, result.role.to_s) if result.respond_to?(:role)
      span.set_attribute(ATTR_GEN_AI_COMPLETION_CONTENT, result.content.to_s)
    elsif result.is_a?(Hash)
      set_completion_attributes(span, result)
    end
  end

  def set_request_attributes(span, params)
    provider = determine_provider(params[:model])
    span.set_attribute(ATTR_GEN_AI_PROVIDER, provider)
    span.set_attribute(ATTR_GEN_AI_REQUEST_MODEL, params[:model])
    span.set_attribute(ATTR_GEN_AI_REQUEST_TEMPERATURE, params[:temperature]) if params[:temperature]
  end

  def set_prompt_messages(span, messages)
    messages.each_with_index do |msg, idx|
      role = msg[:role] || msg['role']
      content = msg[:content] || msg['content']

      span.set_attribute(format(ATTR_GEN_AI_PROMPT_ROLE, idx), role)
      span.set_attribute(format(ATTR_GEN_AI_PROMPT_CONTENT, idx), content.to_s)
    end
  end

  def set_metadata_attributes(span, params)
    session_id = params[:conversation_id].present? ? "#{params[:account_id]}_#{params[:conversation_id]}" : nil
    span.set_attribute(ATTR_LANGFUSE_USER_ID, params[:account_id].to_s) if params[:account_id]
    span.set_attribute(ATTR_LANGFUSE_SESSION_ID, session_id) if session_id.present?
    span.set_attribute(ATTR_LANGFUSE_TAGS, [params[:feature_name]].to_json)

    return unless params[:metadata].is_a?(Hash)

    params[:metadata].each do |key, value|
      span.set_attribute(format(ATTR_LANGFUSE_METADATA, key), value.to_s)
    end
  end
end
