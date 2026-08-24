class Captain::ToolCatalog::ResponseClassifier
  def initialize(provider_key:, source:)
    @provider_key = provider_key
    @source = source
  end

  def classify(body)
    payload = JSON.parse(body)
    classify_slack!(payload) if provider_key == 'slack'
    classify_graphql!(payload) if source == 'graphql'
    payload
  rescue JSON::ParserError
    raise Captain::ToolCatalog::ExecutionError.new('invalid_response', 'invalid_json_response')
  end

  private

  attr_reader :provider_key, :source

  def classify_slack!(payload)
    return unless payload.is_a?(Hash) && payload['ok'] == false

    raise mapped_provider_error(payload['error'])
  end

  def classify_graphql!(payload)
    validate_graphql_errors!(payload)
    validate_shopify_user_errors!(payload)
    data = payload['data'] if payload.is_a?(Hash)
    raise Captain::ToolCatalog::ExecutionError.new('invalid_response', 'graphql_data_missing') if data.nil?

    payload.replace(data) if payload.is_a?(Hash) && data.is_a?(Hash)
  end

  def validate_graphql_errors!(payload)
    errors = payload.is_a?(Hash) ? Array(payload['errors']) : []
    raise mapped_graphql_error(errors.first) if errors.any?
  end

  def validate_shopify_user_errors!(payload)
    return unless provider_key == 'shopify' && user_errors?(payload)

    raise Captain::ToolCatalog::ExecutionError.new('validation', 'provider_validation_failed')
  end

  def user_errors?(value)
    return value.any? { |key, child| key == 'userErrors' ? Array(child).any? : user_errors?(child) } if value.is_a?(Hash)
    return value.any? { |child| user_errors?(child) } if value.is_a?(Array)

    false
  end

  def mapped_graphql_error(error)
    code = error.to_h.dig('extensions', 'code').to_s.downcase
    return Captain::ToolCatalog::ExecutionError.new('authentication', 'provider_authentication_failed') if code.include?('auth')
    return Captain::ToolCatalog::ExecutionError.new('authorization', 'provider_authorization_failed') if code.include?('forbidden')
    return Captain::ToolCatalog::ExecutionError.new('rate_limit', 'provider_rate_limited') if code.include?('rate')

    Captain::ToolCatalog::ExecutionError.new('upstream', 'graphql_request_failed')
  end

  def mapped_provider_error(code)
    value = code.to_s
    return Captain::ToolCatalog::ExecutionError.new('authentication', 'provider_authentication_failed') if value.match?(/auth|token|account_inactive/)
    return Captain::ToolCatalog::ExecutionError.new('authorization', 'provider_authorization_failed') if value.match?(/permission|scope|forbidden/)
    return Captain::ToolCatalog::ExecutionError.new('rate_limit', 'provider_rate_limited') if value.match?(/rate|ratelimited/)
    return Captain::ToolCatalog::ExecutionError.new('not_found', 'provider_resource_not_found') if value.include?('not_found')
    return Captain::ToolCatalog::ExecutionError.new('validation', 'provider_validation_failed') if value.match?(/invalid|missing|bad_/)

    Captain::ToolCatalog::ExecutionError.new('upstream', 'provider_request_failed')
  end
end
