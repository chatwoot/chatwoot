module Captain::ResponsesConfig
  def self.options(model:, temperature:, feature: 'assistant', account: nil)
    options = { temperature: Llm::Models.temperature_for(model, temperature) }
    return options unless Llm::Models.provider_for(model) == 'openai' && Llm::FeatureRouter.standard_openai_endpoint?

    options[:protocol] = :responses
    effort = Llm::FeatureRouter.reasoning_effort(feature: feature, model: model, account: account)
    options[:thinking] = { effort: effort } if effort
    options[:temperature] = nil if effort && effort != :none
    options
  end

  def self.metadata(chat, protocol: nil)
    return {} unless chat.provider.slug == 'openai'

    {
      api_protocol: protocol || chat.provider.config.openai_protocol,
      reasoning_effort: chat.thinking&.dig(:effort)
    }.compact
  end
end
