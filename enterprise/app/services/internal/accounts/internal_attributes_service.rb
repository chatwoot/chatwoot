class Internal::Accounts::InternalAttributesService
  attr_reader :account

  # List of keys that can be managed through this service
  # TODO: Add account_notes field in future
  # This field can be used to store notes about account on Chatwoot cloud
  VALID_KEYS = %w[manually_managed_features].freeze

  def initialize(account)
    @account = account
  end

  # Get a value from internal_attributes
  def get(key)
    validate_key!(key)
    account.internal_attributes[key]
  end

  # Set a value in internal_attributes
  def set(key, value)
    validate_key!(key)

    # Create a new hash to avoid modifying the original
    new_attrs = account.internal_attributes.dup || {}
    new_attrs[key] = value

    # Update the account
    account.internal_attributes = new_attrs
    account.save!
  end

  # Get manually managed features
  def manually_managed_features
    get('manually_managed_features') || []
  end

  # Set manually managed features
  def manually_managed_features=(features)
    features = [] if features.nil?
    features = [features] unless features.is_a?(Array)

    # Clean up the array: remove empty strings, whitespace, and validate against valid features
    valid_features = valid_feature_list
    features = features.compact
                       .map(&:strip)
                       .reject(&:empty?)
                       .select { |f| valid_features.include?(f) }
                       .uniq

    set('manually_managed_features', features)
  end

  # Get list of valid features that can be manually managed
  def valid_feature_list
    # Business and Enterprise plan features only
    Enterprise::Billing::HandleStripeEventService::BUSINESS_PLAN_FEATURES +
      Enterprise::Billing::HandleStripeEventService::ENTERPRISE_PLAN_FEATURES
  end

  # Account notes functionality removed for now
  # Will be re-implemented when UI is ready

  private

  def validate_key!(key)
    raise ArgumentError, "Invalid internal attribute key: #{key}" unless VALID_KEYS.include?(key)
  end
end
