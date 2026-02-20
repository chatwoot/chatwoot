class Captain::Documents::ContextGenerationService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  MAX_DOCUMENT_CHARACTERS = 20_000
  MAX_CHUNK_CHARACTERS = 6_000
  DEFAULT_MODEL = 'gpt-4.1'.freeze

  def initialize(document_content:, chunk_content:, account_id:, model: nil)
    super()
    @document_content = document_content.to_s
    @chunk_content = chunk_content.to_s
    @account_id = account_id
    @model = resolve_model(model)
  end

  def generate
    return '' if @chunk_content.blank?

    response = instrument_llm_call(instrumentation_params) do
      chat(model: @model, temperature: 0.1)
        .with_instructions(system_prompt)
        .ask(user_prompt)
    end

    response.content.to_s.strip
  rescue RubyLLM::Error => e
    Rails.logger.error "Context generation failed: #{e.message}"
    ''
  end

  private

  def system_prompt
    <<~PROMPT
      You are writing retrieval context for a knowledge-base chunk.
      Output 2 concise sentences that make this chunk easier to find for user questions.
      Focus on:
      - user intents this chunk can answer
      - product terms and alternate phrasings users may search for
      - key actions, settings, limits, or troubleshooting signals
      Keep it factual. Do not mention "this chunk" or "this section".
      Do not add information that is not supported by the document or chunk.
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      <document>
      #{truncated_document}
      </document>

      <chunk>
      #{truncated_chunk}
      </chunk>
    PROMPT
  end

  def truncated_document
    @document_content.first(MAX_DOCUMENT_CHARACTERS)
  end

  def truncated_chunk
    @chunk_content.first(MAX_CHUNK_CHARACTERS)
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.chunk_context',
      model: @model,
      temperature: 0.1,
      feature_name: 'chunk_context_generation',
      account_id: @account_id,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: user_prompt }
      ]
    }
  end

  def resolve_model(model)
    return model if model.present?

    context_model = InstallationConfig.find_by(name: 'CAPTAIN_CONTEXT_GENERATION_MODEL')&.value.presence
    open_ai_model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence
    context_model || open_ai_model || DEFAULT_MODEL
  end
end
