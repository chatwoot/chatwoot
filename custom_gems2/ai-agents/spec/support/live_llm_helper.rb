# frozen_string_literal: true

# Helper utilities for running live LLM integration specs.
# These specs are tagged :live_llm and only run when explicitly enabled.
module LiveLLMHelper
  DEFAULT_LIVE_MODEL = "gpt-4o-mini"

  def configure_live_llm(model: live_model)
    Agents.configure do |config|
      config.openai_api_key = ENV["OPENAI_API_KEY"]
      config.default_model = model
      config.request_timeout = Integer(ENV.fetch("OPENAI_REQUEST_TIMEOUT", 30))
      config.debug = false
    end
  end

  def live_model
    ENV.fetch("OPENAI_MODEL", DEFAULT_LIVE_MODEL)
  end
end
