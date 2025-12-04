# frozen_string_literal: true

class Captain::Providers::Factory
  def self.create
    provider_name = Captain::Config.current_provider

    case provider_name.to_s.downcase
    when 'openai', ''
      Captain::Providers::OpenaiProvider.new
    when 'gemini'
      Captain::Providers::GeminiProvider.new
    else
      raise ArgumentError, "Unknown LLM provider: #{provider_name}"
    end
  end
end
