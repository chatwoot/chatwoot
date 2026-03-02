# frozen_string_literal: true

# Sidekiq job that streams an LLM response via ActionCable.
# Enqueued by the LLM completions controller for streaming requests.
#
# Usage:
#   LlmStreamJob.perform_async(
#     account_id, request_id,
#     { "model" => "gpt-4.1-mini", "messages" => [...], "temperature" => 0.7 }
#   )
#
class LlmStreamJob < ApplicationJob
  queue_as :default

  def perform(account_id, request_id, params)
    account = Account.find(account_id)
    model = params['model'] || LlmConstants::DEFAULT_MODEL
    messages = params['messages']
    options = params.slice('temperature', 'max_tokens', 'top_p', 'tools', 'tool_choice').symbolize_keys
    api_key = params['api_key'] # BYOK support
    feature = params['feature']

    client = Llm::Client.new(model: model, api_key: api_key)
    collected_content = +''
    usage_data = {}

    client.chat_stream(messages: messages, **options) do |chunk|
      delta = chunk.dig('choices', 0, 'delta', 'content')
      collected_content << delta if delta.present?

      # Broadcast each chunk to the frontend
      LlmChannel.broadcast_chunk(
        account_id: account_id,
        request_id: request_id,
        delta: delta || ''
      )

      # Capture usage from the final chunk
      usage_data = chunk['usage'] if chunk['usage'].present?
    end

    # Record token usage for billing
    record_usage(account, model, usage_data, feature) if usage_data.present?

    # Broadcast completion
    LlmChannel.broadcast_complete(
      account_id: account_id,
      request_id: request_id,
      usage: usage_data
    )
  rescue Llm::Client::RequestError => e
    LlmChannel.broadcast_error(
      account_id: account_id,
      request_id: request_id,
      error: e.message
    )
    Rails.logger.error("[LlmStreamJob] Request failed: #{e.message}")
  rescue StandardError => e
    LlmChannel.broadcast_error(
      account_id: account_id,
      request_id: request_id,
      error: 'An unexpected error occurred'
    )
    Rails.logger.error("[LlmStreamJob] Unexpected error: #{e.message}")
    raise
  end

  private

  def record_usage(account, model, usage_data, feature)
    provider = resolve_provider(model)
    Saas::AiUsageRecord.record_usage!(
      account: account,
      provider: provider,
      model: model,
      tokens_input: usage_data['prompt_tokens'] || 0,
      tokens_output: usage_data['completion_tokens'] || 0,
      cost_microcents: calculate_cost(model, usage_data),
      feature: feature
    )
  end

  def resolve_provider(model)
    LlmConstants::PROVIDER_PREFIXES.each do |provider, prefixes|
      return provider if prefixes.any? { |prefix| model.start_with?(prefix) }
    end
    'unknown'
  end

  def calculate_cost(model, usage_data)
    config = llm_config_for(model)
    return 0 unless config

    multiplier = config['credit_multiplier'] || 1
    total_tokens = (usage_data['prompt_tokens'] || 0) + (usage_data['completion_tokens'] || 0)
    # Base cost: 1 microcent per token, scaled by credit multiplier
    total_tokens * multiplier
  end

  def llm_config_for(model)
    @llm_config ||= YAML.safe_load(Rails.root.join('config/llm.yml').read)
    @llm_config.dig('models', model)
  end
end
