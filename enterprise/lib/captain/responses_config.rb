module Captain::ResponsesConfig
  def self.options(model:, temperature:, feature: 'assistant')
    options = { temperature: model.to_s.start_with?('gpt-5-mini') ? nil : temperature }
    return options unless Llm::Models.provider_for(model) == 'openai' && Llm::FeatureRouter.standard_openai_endpoint?

    options[:temperature] = nil if RubyLLM.models.find(model).metadata[:temperature] == false
    options[:protocol] = :responses
    effort = Llm::FeatureRouter.reasoning_effort(feature: feature, model: model)
    options[:thinking] = { effort: effort } if effort
    options
  end
end
