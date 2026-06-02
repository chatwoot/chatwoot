# frozen_string_literal: true

# Chatwit: pin RubyLLM's model registry to our curated catalog at boot.
#
# RubyLLM resolves a model's provider from its registry file. Chatwoot only points
# the registry at config/llm_models.json lazily (Llm::Config#configure_ruby_llm), and
# the AI Agents engine (config/initializers/ai_agents.rb) never sets it at all. So
# whichever engine first touches RubyLLM.models can memoize the gem's *default*
# registry — which lacks our manually-added vanguard models (gemini-3.1-flash-lite,
# gemini-3.5-flash, gpt-5.5) — making Gemini model selection raise ModelNotFoundError.
#
# Forcing the file + an eager load at boot guarantees both engines (agent/copilot and
# RubyLLM tasks) resolve the same catalog. Named zz_ so it runs after ai_agents.rb.
Rails.application.config.after_initialize do
  registry = Rails.root.join('config/llm_models.json').to_s
  next unless File.exist?(registry)

  RubyLLM.configure { |config| config.model_registry_file = registry }
  RubyLLM.models.load_from_json!(registry)
rescue StandardError => e
  Rails.logger.error "[CHATWIT][LLM] Failed to pin model registry: #{e.message}"
end
