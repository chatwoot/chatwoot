class Captain::ToolCatalog::StripeConnection
  PROVIDER_KEY = 'stripe'.freeze
  ACCOUNT_URL = 'https://api.stripe.com/v1/account'.freeze
  RESTRICTED_KEY_PATTERN = /\Ark_(?:live|test)_[A-Za-z0-9]{16,}\z/
  MAX_RESPONSE_SIZE = 64.kilobytes
  SCOPE_CHECK_URLS = {
    'customers:read' => 'https://api.stripe.com/v1/customers?limit=1',
    'invoices:read' => 'https://api.stripe.com/v1/invoices?limit=1',
    'payment_intents:read' => 'https://api.stripe.com/v1/payment_intents?limit=1',
    'subscriptions:read' => 'https://api.stripe.com/v1/subscriptions?limit=1'
  }.freeze

  def initialize(account:)
    @account = account
  end

  def connect!(credential:, required_scopes:)
    require_encryption!
    validate_credential!(credential)
    scopes = normalize_scopes(required_scopes)
    stripe_account = fetch_json(ACCOUNT_URL, credential)
    validate_account!(stripe_account)
    scopes.each do |scope|
      validate_resource_list!(fetch_json(SCOPE_CHECK_URLS.fetch(scope), credential, scope: scope))
    end
    persist_hook!(stripe_account, credential, scopes)
  end

  private

  attr_reader :account

  def require_encryption!
    return if Chatwoot.encryption_configured?

    raise Captain::ToolCatalog::WorkflowError, 'encryption_required'
  end

  def validate_credential!(credential)
    return if credential.is_a?(String) && credential.match?(RESTRICTED_KEY_PATTERN)

    raise Captain::ToolCatalog::WorkflowError, 'stripe_restricted_key_required'
  end

  def normalize_scopes(required_scopes)
    scopes = Array(required_scopes).filter_map { |scope| scope.to_s.presence }.uniq.sort
    unsupported = scopes - SCOPE_CHECK_URLS.keys
    return scopes if unsupported.empty?

    raise Captain::ToolCatalog::WorkflowError, 'stripe_scope_unsupported'
  end

  def fetch_json(url, credential, scope: nil)
    JSON.parse(fetch_response_body(url, credential))
  rescue SafeFetch::HttpError => e
    raise http_error(e.message, scope)
  rescue SafeFetch::FileTooLargeError, JSON::ParserError
    raise Captain::ToolCatalog::WorkflowError, 'stripe_invalid_response'
  rescue SafeFetch::FetchError
    raise Captain::ToolCatalog::WorkflowError, 'stripe_unavailable'
  rescue SafeFetch::Error
    raise Captain::ToolCatalog::WorkflowError, 'stripe_connection_failed'
  end

  def fetch_response_body(url, credential)
    response_body = +''
    headers = { 'Authorization' => "Bearer #{credential}" }
    SafeFetch.fetch(
      url,
      method: :get,
      headers: headers,
      sensitive_headers: headers.keys,
      max_bytes: MAX_RESPONSE_SIZE,
      validate_content_type: false
    ) do |result|
      response_body = result.tempfile.read
    end
    response_body
  end

  def http_error(message, scope)
    status = message.to_s[/\A\d{3}/].to_i
    return Captain::ToolCatalog::WorkflowError.new('stripe_authentication_failed') if status == 401
    return Captain::ToolCatalog::WorkflowError.new('stripe_scope_missing') if status == 403 && scope.present?
    return Captain::ToolCatalog::WorkflowError.new('stripe_rate_limited') if status == 429

    Captain::ToolCatalog::WorkflowError.new('stripe_connection_failed')
  end

  def validate_account!(stripe_account)
    valid = stripe_account.is_a?(Hash) && stripe_account['object'] == 'account' && stripe_account['id'].to_s.start_with?('acct_')
    return if valid

    raise Captain::ToolCatalog::WorkflowError, 'stripe_invalid_response'
  end

  def validate_resource_list!(response)
    return if response.is_a?(Hash) && response['object'] == 'list' && response['data'].is_a?(Array)

    raise Captain::ToolCatalog::WorkflowError, 'stripe_invalid_response'
  end

  def persist_hook!(stripe_account, credential, scopes)
    account.with_lock do
      hook = account.hooks.account_hooks.find_or_initialize_by(app_id: PROVIDER_KEY)
      hook.assign_attributes(
        access_token: credential,
        reference_id: stripe_account.fetch('id'),
        settings: safe_settings(stripe_account, scopes),
        status: 'enabled'
      )
      hook.save!
      hook
    end
  end

  def safe_settings(stripe_account, scopes)
    {
      'account_name' => stripe_account.dig('business_profile', 'name').presence || stripe_account.fetch('id'),
      'external_id' => stripe_account.fetch('id'),
      'livemode' => stripe_account['livemode'] == true,
      'scopes' => scopes,
      'validated_at' => Time.current.utc.iso8601
    }
  end
end
