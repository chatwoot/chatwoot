# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class SessionCreateParams < ::Stripe::RequestParams
      class AccountHolder < ::Stripe::RequestParams
        # The ID of the Stripe account whose accounts will be retrieved. Should only be present if `type` is `account`.
        attr_accessor :account
        # The ID of the Stripe customer whose accounts will be retrieved. Should only be present if `type` is `customer`.
        attr_accessor :customer
        # Type of account holder to collect accounts for.
        attr_accessor :type

        def initialize(account: nil, customer: nil, type: nil)
          @account = account
          @customer = customer
          @type = type
        end
      end

      class Filters < ::Stripe::RequestParams
        # Restricts the Session to subcategories of accounts that can be linked. Valid subcategories are: `checking`, `savings`, `mortgage`, `line_of_credit`, `credit_card`.
        attr_accessor :account_subcategories
        # List of countries from which to collect accounts.
        attr_accessor :countries

        def initialize(account_subcategories: nil, countries: nil)
          @account_subcategories = account_subcategories
          @countries = countries
        end
      end
      # The account holder to link accounts for.
      attr_accessor :account_holder
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Filters to restrict the kinds of accounts to collect.
      attr_accessor :filters
      # List of data features that you would like to request access to.
      #
      # Possible values are `balances`, `transactions`, `ownership`, and `payment_method`.
      attr_accessor :permissions
      # List of data features that you would like to retrieve upon account creation.
      attr_accessor :prefetch
      # For webview integrations only. Upon completing OAuth login in the native browser, the user will be redirected to this URL to return to your app.
      attr_accessor :return_url

      def initialize(
        account_holder: nil,
        expand: nil,
        filters: nil,
        permissions: nil,
        prefetch: nil,
        return_url: nil
      )
        @account_holder = account_holder
        @expand = expand
        @filters = filters
        @permissions = permissions
        @prefetch = prefetch
        @return_url = return_url
      end
    end
  end
end
