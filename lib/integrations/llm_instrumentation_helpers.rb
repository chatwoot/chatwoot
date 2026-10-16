# frozen_string_literal: true

module Integrations::LlmInstrumentationHelpers
  include Integrations::LlmInstrumentationConstants
  include Integrations::LlmInstrumentationContext
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
    set_langfuse_attributes(span, current_langfuse_attributes.merge(propagated_langfuse_attributes(params)))
    set_langfuse_attributes(span, current_observation_metadata_attributes.merge(propagated_observation_metadata_attributes(params)))
  end

  def propagated_langfuse_attributes(params)
    attrs = {}
    session_id = params[:conversation_id].present? ? "#{params[:account_id]}_#{params[:conversation_id]}" : nil

    attrs[ATTR_LANGFUSE_USER_ID] = params[:account_id].to_s if params[:account_id]
    attrs[ATTR_LANGFUSE_SESSION_ID] = session_id if session_id.present?
    attrs[ATTR_LANGFUSE_TAGS] = [params[:feature_name].to_s] if params[:feature_name].present?

    return attrs unless params[:metadata].is_a?(Hash)

    params[:metadata].each do |key, value|
      attrs[format(ATTR_LANGFUSE_METADATA, key)] = value.to_s
    end

    attrs
  end

  def propagated_observation_metadata_attributes(params)
    attrs = {}
    session_id = params[:conversation_id].present? ? "#{params[:account_id]}_#{params[:conversation_id]}" : nil

    add_observation_metadata(attrs, 'user_id', params[:account_id])
    add_observation_metadata(attrs, 'account_id', params[:account_id])
    add_observation_metadata(attrs, 'session_id', session_id)
    add_observation_metadata(attrs, 'trace_tags', [params[:feature_name]].to_json)
    add_observation_metadata(attrs, 'feature_name', params[:feature_name])

    return attrs unless params[:metadata].is_a?(Hash)

    params[:metadata].each do |key, value|
      add_observation_metadata(attrs, key, value)
    end

    attrs
  end

  def add_observation_metadata(attrs, key, value)
    return if value.blank?

    attrs[format(ATTR_LANGFUSE_OBSERVATION_METADATA, key)] = value.to_s
  end

  def set_langfuse_attributes(span, attrs)
    attrs.each do |key, value|
      span.set_attribute(key, value)
    end
  end
end
