class Captain::Llm::FailureLogger
  # Records an LLM/API misconfiguration or runtime failure so it can be surfaced
  # in the Super Admin console. The provider/model/endpoint are captured from the
  # current config at the moment of failure, so a log row always shows the exact
  # settings that caused it even if they are changed afterwards.
  def self.record(source:, error:, **attributes)
    return unless Captain::LlmFailureLog.table_exists?

    model = attributes[:model]
    Captain::LlmFailureLog.create!(
      source: source,
      error_message: error.respond_to?(:message) ? error.message.to_s : error.to_s,
      error_class: error.class.name,
      error_code: attributes[:error_code],
      provider: Llm::Config.provider_for(model || Llm::Config.model),
      model: model || Llm::Config.model,
      endpoint: Llm::Config.api_base,
      account_id: attributes[:account_id],
      assistant_id: attributes[:assistant_id],
      conversation_id: attributes[:conversation_id],
      request_messages: attributes[:request_messages]
    )
  rescue StandardError => e
    # Persisting the failure log must never break the caller's own error handling.
    Rails.logger.error "[Captain FailureLogger] failed to record LLM failure: #{e.message}"
  end

  # Runs a lightweight end-to-end check against the currently configured LLM
  # settings, returning a structured per-setting result for the health-check UI.
  def self.check_config
    {
      api_key: config_status(configured: Llm::Config.system_api_key.present?, label: 'AI Agent API key'),
      endpoint: config_status(configured: Llm::Config.openai_endpoint.present?, label: 'AI Agent endpoint'),
      chat_model: config_status(configured: Llm::Config.installation_model.present?, label: 'Chat model'),
      embedding_model: config_status(configured: true, label: 'Embedding model'),
      firecrawl_key: config_status(configured: Llm::Config.firecrawl_api_key.present?, label: 'Firecrawl key'),
      embedding: embedding_health_check,
      configuration: {
        endpoint: Llm::Config.api_base,
        chat_model: Llm::Config.model,
        embedding_model: Llm::Config.embedding_model,
        firecrawl_key_present: Llm::Config.firecrawl_api_key.present?
      }
    }
  end

  def self.embedding_health_check
    return { status: 'skipped', message: 'No AI Agent API key configured to test embedding.' } if Llm::Config.system_api_key.blank?

    embedding = Captain::Llm::EmbeddingService.new.get_embedding('health check probe')
    { status: 'ok', message: "Embedding produced #{embedding.size} dimensions." }
  rescue StandardError => e
    { status: 'failed', message: e.message }
  end

  def self.config_status(configured:, label:)
    {
      label: label,
      status: configured ? 'configured' : 'missing',
      message: configured ? 'Configured' : 'Not configured'
    }
  end
end
