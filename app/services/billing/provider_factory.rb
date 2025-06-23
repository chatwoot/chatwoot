# frozen_string_literal: true

module Billing
  # This factory is responsible for creating an instance of the currently
  # configured payment provider. It allows the billing services to be
  # provider-agnostic.
  class ProviderFactory
    def self.get_provider
      provider_name = ENV.fetch('PAYMENT_PROVIDER', 'stripe').camelize
      provider_class = "Billing::Providers::#{provider_name}".constantize
      provider_class.new
    rescue NameError
      raise "Unsupported payment provider: #{provider_name}"
    end
  end
end