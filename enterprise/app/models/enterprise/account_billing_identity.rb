module Enterprise::AccountBillingIdentity
  extend ActiveSupport::Concern

  BILLING_PROVIDERS = %w[stripe shopify].freeze
  SIGNUP_SOURCES = %w[chatwoot shopify].freeze
  DEFAULT_BILLING_PROVIDER = 'stripe'.freeze
  DEFAULT_SIGNUP_SOURCE = 'chatwoot'.freeze

  included do
    validates :billing_provider, inclusion: { in: BILLING_PROVIDERS }
    validates :signup_source, inclusion: { in: SIGNUP_SOURCES }
    validate :validate_billing_identity_immutability, on: :update
  end

  def billing_provider
    normalized_internal_attributes['billing_provider'].presence || DEFAULT_BILLING_PROVIDER
  end

  def billing_provider=(provider)
    self.internal_attributes = normalized_internal_attributes.merge('billing_provider' => provider.to_s)
  end

  def signup_source
    normalized_internal_attributes['signup_source'].presence || DEFAULT_SIGNUP_SOURCE
  end

  def signup_source=(source)
    self.internal_attributes = normalized_internal_attributes.merge('signup_source' => source.to_s)
  end

  private

  def normalized_internal_attributes
    (internal_attributes || {}).stringify_keys
  end

  def validate_billing_identity_immutability
    return unless will_save_change_to_internal_attributes?

    validate_immutable_identity(:billing_provider, DEFAULT_BILLING_PROVIDER)
    validate_immutable_identity(:signup_source, DEFAULT_SIGNUP_SOURCE)
  end

  def validate_immutable_identity(attribute, default)
    stored_attributes = (attribute_in_database('internal_attributes') || {}).stringify_keys
    stored_value = stored_attributes[attribute.to_s].presence || default
    errors.add(attribute, 'cannot be changed after account creation') if public_send(attribute) != stored_value
  end
end
