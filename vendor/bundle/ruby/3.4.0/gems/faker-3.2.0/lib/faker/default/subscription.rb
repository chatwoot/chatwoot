# frozen_string_literal: true

module Faker
  class Subscription < Base
    ##
    # Produces the name of a subscription plan.
    #
    # @return [String]
    #
    # @example
    #   Faker::Subscription.plan #=> "Platinum"
    #
    # @faker.version 1.9.2
    def self.plan
      fetch('subscription.plans')
    end

    ##
    # Produces a subscription status.
    #
    # @return [String]
    #
    # @example
    #   Faker::Subscription.status #=> "Active"
    #
    # @faker.version 1.9.2
    def self.status
      fetch('subscription.statuses')
    end

    ##
    # Produces the name of a payment method.
    #
    # @return [String]
    #
    # @example
    #   Faker::Subscription.payment_method #=> "PayPal"
    #
    # @faker.version 1.9.2
    def self.payment_method
      fetch('subscription.payment_methods')
    end

    ##
    # Produces the name of a subscription term.
    #
    # @return [String]
    #
    # @example
    #   Faker::Subscription.subscription_term #=> "Annual"
    #
    # @faker.version 1.9.2
    def self.subscription_term
      fetch('subscription.subscription_terms')
    end

    ##
    # Produces the name of a payment term.
    #
    # @return [String]
    #
    # @example
    #   Faker::Subscription.payment_term #=> "Monthly"
    #
    # @faker.version 1.9.2
    def self.payment_term
      fetch('subscription.payment_terms')
    end
  end
end
