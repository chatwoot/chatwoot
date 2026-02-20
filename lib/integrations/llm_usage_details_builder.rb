# frozen_string_literal: true

module Integrations::LlmUsageDetailsBuilder
  private

  def usage_details_from_hash(usage)
    usage_hash = normalize_usage_hash(usage)
    return {} if usage_hash.blank?

    usage_details_from_hash_values(usage_hash)
  end

  def usage_details_from_hash_values(usage_hash)
    input_tokens_source = usage_hash.key?('input_tokens') ? 'input_tokens' : 'prompt_tokens'
    cache_read_tokens = usage_cache_read_tokens(usage_hash)
    cache_creation_tokens = usage_cache_creation_tokens(usage_hash)
    input_tokens = normalized_uncached_input_tokens(
      usage_hash[input_tokens_source],
      cache_read_tokens,
      input_tokens_source: input_tokens_source
    )
    output_tokens = usage_hash['output_tokens'] || usage_hash['completion_tokens']
    total_tokens = usage_total_tokens(
      usage_hash['total_tokens'],
      input_tokens,
      output_tokens,
      cache_read_tokens,
      cache_creation_tokens
    )

    build_usage_details(input_tokens, output_tokens, total_tokens, cache_read_tokens, cache_creation_tokens)
  end

  def usage_details_from_message(message, provider:)
    input_tokens = message_token(message, :input_tokens)
    output_tokens = message_token(message, :output_tokens)
    cache_read_tokens = message_token(message, :cached_tokens)
    cache_creation_tokens = message_token(message, :cache_creation_tokens)

    input_tokens = normalized_uncached_input_tokens(
      input_tokens,
      cache_read_tokens,
      provider: provider,
      input_tokens_source: 'input_tokens'
    )
    total_tokens = total_tokens_from_parts(input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens)

    build_usage_details(input_tokens, output_tokens, total_tokens, cache_read_tokens, cache_creation_tokens)
  end

  def build_usage_details(input_tokens, output_tokens, total_tokens, cache_read_tokens, cache_creation_tokens)
    compact_usage_details(
      input: input_tokens,
      output: output_tokens,
      total: total_tokens,
      cache_read_input_tokens: cache_read_tokens,
      cache_creation_input_tokens: cache_creation_tokens
    )
  end

  def normalize_usage_hash(usage)
    return usage.deep_stringify_keys if usage.respond_to?(:deep_stringify_keys)
    return usage.to_h.transform_keys(&:to_s) if usage.respond_to?(:to_h)

    {}
  end

  def usage_cache_read_tokens(usage_hash)
    usage_hash['cache_read_input_tokens'] ||
      usage_hash['cached_tokens'] ||
      usage_hash.dig('prompt_tokens_details', 'cached_tokens')
  end

  def usage_cache_creation_tokens(usage_hash)
    usage_hash['cache_creation_input_tokens'] ||
      usage_hash['cache_creation_tokens'] ||
      usage_hash['cache_creation']&.values&.compact&.sum
  end

  def usage_total_tokens(reported_total, input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens)
    if cache_read_tokens || cache_creation_tokens
      total_tokens_from_parts(input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens)
    else
      reported_total || total_tokens_from_parts(input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens)
    end
  end

  def message_token(message, token_name)
    message.respond_to?(token_name) ? message.public_send(token_name) : nil
  end

  def normalized_uncached_input_tokens(input_tokens, cache_read_tokens, provider: nil, input_tokens_source: nil)
    return input_tokens if input_tokens.nil? || cache_read_tokens.nil?

    if input_tokens_source == 'prompt_tokens' || provider == 'openai'
      [input_tokens - cache_read_tokens, 0].max
    else
      input_tokens
    end
  end

  def total_tokens_from_parts(input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens)
    values = [input_tokens, output_tokens, cache_read_tokens, cache_creation_tokens].compact
    values.sum if values.present?
  end

  def compact_usage_details(details)
    details.compact
  end
end
