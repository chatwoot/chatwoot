module Captain::ResponsesConfig
  def self.options(model:, temperature:)
    options = { temperature: model.to_s.start_with?('gpt-5-mini') ? nil : temperature }
    return options unless Llm::Models.provider_for(model) == 'openai' && standard_openai_endpoint?

    options[:protocol] = :responses
    # These models default to no reasoning on Chat Completions. Older GPT-5
    # models do not support none, so leave their reasoning default unchanged.
    options[:thinking] = { effort: :none } if model.match?(/\Agpt-5\.[12](?:-|\z)/)
    options
  end

  def self.standard_openai_endpoint?
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    endpoint.blank? || endpoint.chomp('/') == LlmConstants::OPENAI_API_ENDPOINT
  end
  private_class_method :standard_openai_endpoint?
end
