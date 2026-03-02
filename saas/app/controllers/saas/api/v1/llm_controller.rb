# frozen_string_literal: true

# API controller for LLM completions via the LiteLLM proxy.
#
# POST /saas/api/v1/accounts/:account_id/completions
#   - Blocking (stream: false) → returns full response as JSON
#   - Streaming (stream: true) → enqueues LlmStreamJob, returns request_id
#
# POST /saas/api/v1/accounts/:account_id/embeddings
#   - Returns embedding vectors
#
# GET /saas/api/v1/accounts/:account_id/models
#   - Returns available models from config/llm.yml
#
class Saas::Api::V1::LlmController < Api::V1::Accounts::BaseController
  before_action :authorize_llm
  before_action :check_usage_limits, only: [:completions]

  def completions
    if completion_params[:stream]
      handle_streaming_completion
    else
      handle_blocking_completion
    end
  end

  def embeddings
    client = build_client
    response = client.embed(
      input: params[:input],
      model: params[:model]
    )
    render json: response
  rescue Llm::Client::RequestError => e
    render json: { error: e.message }, status: e.status || :bad_gateway
  end

  def models
    available_models = llm_config['models'].map do |name, details|
      {
        id: name,
        provider: details['provider'],
        display_name: details['display_name'],
        credit_multiplier: details['credit_multiplier'],
        coming_soon: details['coming_soon'] || false
      }
    end
    render json: { models: available_models }
  end

  def health
    client = Llm::Client.new
    render json: { healthy: client.healthy? }
  end

  private

  def authorize_llm
    authorize(:llm, policy_class: Saas::LlmPolicy)
  end

  def handle_blocking_completion
    client = build_client
    response = client.chat(
      messages: completion_params[:messages],
      **completion_options
    )

    # Record usage for billing
    record_usage(response) if response['usage'].present?

    render json: response
  rescue Llm::Client::RequestError => e
    render json: { error: e.message }, status: e.status || :bad_gateway
  end

  def handle_streaming_completion
    request_id = SecureRandom.uuid
    LlmStreamJob.perform_later(
      current_account.id,
      request_id,
      {
        'model' => completion_params[:model] || LlmConstants::DEFAULT_MODEL,
        'messages' => completion_params[:messages],
        'temperature' => completion_params[:temperature],
        'max_tokens' => completion_params[:max_tokens],
        'top_p' => completion_params[:top_p],
        'tools' => completion_params[:tools],
        'tool_choice' => completion_params[:tool_choice],
        'api_key' => completion_params[:api_key],
        'feature' => completion_params[:feature]
      }.compact
    )
    render json: { request_id: request_id, stream: true }
  end

  def build_client
    Llm::Client.new(
      model: completion_params[:model],
      api_key: completion_params[:api_key]
    )
  end

  def completion_options
    completion_params
      .slice(:temperature, :max_tokens, :top_p, :tools, :tool_choice)
      .to_h
      .symbolize_keys
  end

  def record_usage(response)
    usage = response['usage']
    model = completion_params[:model] || LlmConstants::DEFAULT_MODEL
    provider = resolve_provider(model)

    Saas::AiUsageRecord.record_usage!(
      account: current_account,
      provider: provider,
      model: model,
      tokens_input: usage['prompt_tokens'] || 0,
      tokens_output: usage['completion_tokens'] || 0,
      cost_microcents: calculate_cost(model, usage),
      feature: completion_params[:feature]
    )
  end

  def check_usage_limits
    return unless current_account.respond_to?(:ai_usage_exceeded?) && current_account.ai_usage_exceeded?

    render json: {
      error: 'AI token quota exceeded for this billing period. Please upgrade your plan.',
      tokens_remaining: 0
    }, status: :payment_required
  end

  def resolve_provider(model)
    LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end
    'unknown'
  end

  def calculate_cost(model, usage)
    model_config = llm_config.dig('models', model)
    return 0 unless model_config

    multiplier = model_config['credit_multiplier'] || 1
    total_tokens = (usage['prompt_tokens'] || 0) + (usage['completion_tokens'] || 0)
    total_tokens * multiplier
  end

  # Cache the LLM config YAML — reloaded per-request in dev, cached in production
  def llm_config
    if Rails.env.production?
      @@llm_config ||= YAML.safe_load(Rails.root.join('config/llm.yml').read) # rubocop:disable Style/ClassVars
    else
      YAML.safe_load(Rails.root.join('config/llm.yml').read)
    end
  end

  def completion_params
    @completion_params ||= params.permit(
      :model, :stream, :temperature, :max_tokens, :top_p,
      :tool_choice, :api_key, :feature, :input,
      messages: [:role, :content, :name, { content: [:type, :text, { image_url: [:url, :detail] }] }],
      tools: [:type, { function: [:name, :description, { parameters: {} }] }]
    )
  end
end
