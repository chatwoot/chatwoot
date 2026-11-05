# A manifest tool can keep values from its response for the rest of the conversation, and a later tool of the same
# toolset can take them. Chatwoot writes the values, never the model, so a tool that stores values may not take any
# value from the model. Every stored value then traces back to the verified email.
module Concerns::ToolStorable
  extend ActiveSupport::Concern

  STORED_SOURCE_PREFIX = 'stored.'.freeze
  STORE_NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/

  included do
    validate :validate_stored_values
  end

  def stored_params
    param_schema.select { |param_def| param_def['source'].to_s.start_with?(STORED_SOURCE_PREFIX) }
  end

  # Stored values are kept per toolset installation, so toolsets never read each other's values
  def store_namespace
    source_metadata&.dig('installation_id')
  end

  # The enabled tools of the same toolset install that store this name, by the name the model calls them
  def store_writers(name)
    assistant.custom_tools.enabled.where("source_metadata->>'installation_id' = ?", store_namespace)
             .select { |tool| tool.stores.key?(name) }.map(&:slug)
  end

  # Checked again when a response comes back, so a row changed outside validation still cannot store model input
  def stores_values?
    stores.present? && store_namespace.present? && !takes_model_values?
  end

  private

  def validate_stored_values
    return if stores.blank? && stored_params.empty?
    return errors.add(:stores, I18n.t('captain.custom_tool.stores.manifest_only')) if store_namespace.blank?
    return errors.add(:stores, I18n.t('captain.custom_tool.stores.invalid')) unless valid_stores?

    errors.add(:stores, I18n.t('captain.custom_tool.stores.unbound')) if stores.present? && takes_model_values?
  end

  def takes_model_values?
    param_schema.any? { |param_def| param_def['source'].blank? }
  end

  # Each name maps to a JMESPath expression that picks the values from the response
  def valid_stores?
    stores.is_a?(Hash) && stores.all? do |name, expression|
      STORE_NAME_PATTERN.match?(name) && expression.is_a?(String) && JMESPath.search(expression, {}).then { true }
    end
  rescue JMESPath::Errors::SyntaxError
    false
  end
end
