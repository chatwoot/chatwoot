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
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    model = params[:model] || 'text-embedding-3-small'
    client = build_client

    response = client.embed(
      input: params[:input],
      model: model
    )

    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    log_llm_request(action: 'embeddings', model: model, duration_ms: duration_ms, status: 'success')

    render json: response
  rescue Llm::Client::RequestError => e
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    log_llm_request(action: 'embeddings', model: model, duration_ms: duration_ms, status: 'error', error: e.message)
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
    checks = {
      litellm: check_litellm,
      database: check_database,
      pgvector: check_pgvector,
      redis: check_redis
    }

    healthy = checks.values.all? { |c| c[:status] == 'ok' }
    status_code = healthy ? :ok : :service_unavailable

    render json: { healthy: healthy, checks: checks }, status: status_code
  end

  private

  def authorize_llm
    authorize(:llm, policy_class: Saas::LlmPolicy)
  end

  def handle_blocking_completion
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    client = build_client
    model = completion_params[:model] || LlmConstants::DEFAULT_MODEL

    response = client.chat(
      messages: completion_params[:messages],
      **completion_options
    )

    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

    # Record usage for billing
    record_usage(response) if response['usage'].present?

    log_llm_request(
      action: 'completions',
      model: model,
      tokens_input: response.dig('usage', 'prompt_tokens'),
      tokens_output: response.dig('usage', 'completion_tokens'),
      duration_ms: duration_ms,
      status: 'success'
    )

    render json: response
  rescue Llm::Client::RequestError => e
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    log_llm_request(action: 'completions', model: model, duration_ms: duration_ms, status: 'error', error: e.message)
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

  # Cache the LLM config YAML — thread-safe via Mutex
  LLM_CONFIG_MUTEX = Mutex.new

  def llm_config
    return YAML.safe_load(Rails.root.join('config/llm.yml').read) unless Rails.env.production?

    LLM_CONFIG_MUTEX.synchronize do
      self.class.instance_variable_get(:@_llm_config) || begin
        config = YAML.safe_load(Rails.root.join('config/llm.yml').read)
        self.class.instance_variable_set(:@_llm_config, config)
        config
      end
    end
  end

  def log_llm_request(action:, model: nil, tokens_input: nil, tokens_output: nil, duration_ms: nil, status: 'success', error: nil)
    Rails.logger.info(
      "[SaaS::LLM] account_id=#{current_account.id} action=#{action} model=#{model} " \
      "tokens_in=#{tokens_input || '-'} tokens_out=#{tokens_output || '-'} " \
      "duration_ms=#{duration_ms || '-'} status=#{status}" \
      "#{error ? " error=#{error.truncate(200)}" : ''}"
    )
  end

  # --- Health check helpers ---

  def check_litellm
    healthy = Llm::Client.new.healthy?
    { status: healthy ? 'ok' : 'error' }
  rescue StandardError => e
    { status: 'error', message: e.message.truncate(100) }
  end

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok' }
  rescue StandardError => e
    { status: 'error', message: e.message.truncate(100) }
  end

  def check_pgvector
    ActiveRecord::Base.connection.execute("SELECT '[1,2,3]'::vector")
    { status: 'ok' }
  rescue StandardError => e
    { status: 'error', message: e.message.truncate(100) }
  end

  def check_redis
    $velma.with { |conn| conn.ping }
    { status: 'ok' }
  rescue StandardError => e
    { status: 'error', message: e.message.truncate(100) }
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
