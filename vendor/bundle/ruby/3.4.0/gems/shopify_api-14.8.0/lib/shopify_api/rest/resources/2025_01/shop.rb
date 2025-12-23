# typed: false
# frozen_string_literal: true

########################################################################################################################
# This file is auto-generated. If you have an issue, please create a GitHub issue.                                     #
########################################################################################################################

module ShopifyAPI
  class Shop < ShopifyAPI::Rest::Base
    extend T::Sig

    @prev_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @next_page_info = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    @api_call_limit = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)
    @retry_request_after = T.let(Concurrent::ThreadLocalVar.new { nil }, Concurrent::ThreadLocalVar)

    sig { params(session: T.nilable(ShopifyAPI::Auth::Session), from_hash: T.nilable(T::Hash[T.untyped, T.untyped])).void }
    def initialize(session: ShopifyAPI::Context.active_session, from_hash: nil)

      @address1 = T.let(nil, T.nilable(String))
      @address2 = T.let(nil, T.nilable(String))
      @auto_configure_tax_inclusivity = T.let(nil, T.nilable(T::Boolean))
      @checkout_api_supported = T.let(nil, T.nilable(T::Boolean))
      @city = T.let(nil, T.nilable(String))
      @country = T.let(nil, T.nilable(String))
      @country_code = T.let(nil, T.nilable(String))
      @country_name = T.let(nil, T.nilable(String))
      @county_taxes = T.let(nil, T.nilable(T::Boolean))
      @created_at = T.let(nil, T.nilable(String))
      @currency = T.let(nil, T.nilable(String))
      @customer_email = T.let(nil, T.nilable(String))
      @domain = T.let(nil, T.nilable(String))
      @eligible_for_payments = T.let(nil, T.nilable(T::Boolean))
      @email = T.let(nil, T.nilable(String))
      @enabled_presentment_currencies = T.let(nil, T.nilable(T::Array[T.untyped]))
      @finances = T.let(nil, T.nilable(T::Boolean))
      @force_ssl = T.let(nil, T.nilable(T::Boolean))
      @google_apps_domain = T.let(nil, T.nilable(String))
      @google_apps_login_enabled = T.let(nil, T.nilable(String))
      @has_discounts = T.let(nil, T.nilable(T::Boolean))
      @has_gift_cards = T.let(nil, T.nilable(T::Boolean))
      @has_storefront = T.let(nil, T.nilable(T::Boolean))
      @iana_timezone = T.let(nil, T.nilable(String))
      @id = T.let(nil, T.nilable(Integer))
      @latitude = T.let(nil, T.nilable(Float))
      @longitude = T.let(nil, T.nilable(Float))
      @marketing_sms_consent_enabled_at_checkout = T.let(nil, T.nilable(T::Boolean))
      @money_format = T.let(nil, T.nilable(String))
      @money_in_emails_format = T.let(nil, T.nilable(String))
      @money_with_currency_format = T.let(nil, T.nilable(String))
      @money_with_currency_in_emails_format = T.let(nil, T.nilable(String))
      @multi_location_enabled = T.let(nil, T.nilable(T::Boolean))
      @myshopify_domain = T.let(nil, T.nilable(String))
      @name = T.let(nil, T.nilable(String))
      @password_enabled = T.let(nil, T.nilable(T::Boolean))
      @phone = T.let(nil, T.nilable(String))
      @plan_display_name = T.let(nil, T.nilable(String))
      @plan_name = T.let(nil, T.nilable(String))
      @pre_launch_enabled = T.let(nil, T.nilable(T::Boolean))
      @primary_locale = T.let(nil, T.nilable(String))
      @primary_location_id = T.let(nil, T.nilable(Integer))
      @province = T.let(nil, T.nilable(String))
      @province_code = T.let(nil, T.nilable(String))
      @requires_extra_payments_agreement = T.let(nil, T.nilable(T::Boolean))
      @setup_required = T.let(nil, T.nilable(T::Boolean))
      @shop_owner = T.let(nil, T.nilable(String))
      @source = T.let(nil, T.nilable(String))
      @tax_shipping = T.let(nil, T.nilable(String))
      @taxes_included = T.let(nil, T.nilable(T::Boolean))
      @timezone = T.let(nil, T.nilable(String))
      @transactional_sms_disabled = T.let(nil, T.nilable(T::Boolean))
      @updated_at = T.let(nil, T.nilable(String))
      @weight_unit = T.let(nil, T.nilable(String))
      @zip = T.let(nil, T.nilable(String))

      super(session: session, from_hash: from_hash)
    end

    @has_one = T.let({}, T::Hash[Symbol, Class])
    @has_many = T.let({}, T::Hash[Symbol, Class])
    @paths = T.let([
      {http_method: :get, operation: :get, ids: [], path: "shop.json"}
    ], T::Array[T::Hash[String, T.any(T::Array[Symbol], String, Symbol)]])

    sig { returns(T.nilable(String)) }
    attr_reader :address1
    sig { returns(T.nilable(String)) }
    attr_reader :address2
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :auto_configure_tax_inclusivity
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :checkout_api_supported
    sig { returns(T.nilable(String)) }
    attr_reader :city
    sig { returns(T.nilable(String)) }
    attr_reader :country
    sig { returns(T.nilable(String)) }
    attr_reader :country_code
    sig { returns(T.nilable(String)) }
    attr_reader :country_name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :county_taxes
    sig { returns(T.nilable(String)) }
    attr_reader :created_at
    sig { returns(T.nilable(String)) }
    attr_reader :currency
    sig { returns(T.nilable(String)) }
    attr_reader :customer_email
    sig { returns(T.nilable(String)) }
    attr_reader :domain
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :eligible_for_payments
    sig { returns(T.nilable(String)) }
    attr_reader :email
    sig { returns(T.nilable(T::Array[String])) }
    attr_reader :enabled_presentment_currencies
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :finances
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :force_ssl
    sig { returns(T.nilable(String)) }
    attr_reader :google_apps_domain
    sig { returns(T.nilable(String)) }
    attr_reader :google_apps_login_enabled
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :has_discounts
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :has_gift_cards
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :has_storefront
    sig { returns(T.nilable(String)) }
    attr_reader :iana_timezone
    sig { returns(T.nilable(Integer)) }
    attr_reader :id
    sig { returns(T.nilable(Float)) }
    attr_reader :latitude
    sig { returns(T.nilable(Float)) }
    attr_reader :longitude
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :marketing_sms_consent_enabled_at_checkout
    sig { returns(T.nilable(String)) }
    attr_reader :money_format
    sig { returns(T.nilable(String)) }
    attr_reader :money_in_emails_format
    sig { returns(T.nilable(String)) }
    attr_reader :money_with_currency_format
    sig { returns(T.nilable(String)) }
    attr_reader :money_with_currency_in_emails_format
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :multi_location_enabled
    sig { returns(T.nilable(String)) }
    attr_reader :myshopify_domain
    sig { returns(T.nilable(String)) }
    attr_reader :name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :password_enabled
    sig { returns(T.nilable(String)) }
    attr_reader :phone
    sig { returns(T.nilable(String)) }
    attr_reader :plan_display_name
    sig { returns(T.nilable(String)) }
    attr_reader :plan_name
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :pre_launch_enabled
    sig { returns(T.nilable(String)) }
    attr_reader :primary_locale
    sig { returns(T.nilable(Integer)) }
    attr_reader :primary_location_id
    sig { returns(T.nilable(String)) }
    attr_reader :province
    sig { returns(T.nilable(String)) }
    attr_reader :province_code
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :requires_extra_payments_agreement
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :setup_required
    sig { returns(T.nilable(String)) }
    attr_reader :shop_owner
    sig { returns(T.nilable(String)) }
    attr_reader :source
    sig { returns(T.nilable(String)) }
    attr_reader :tax_shipping
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :taxes_included
    sig { returns(T.nilable(String)) }
    attr_reader :timezone
    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :transactional_sms_disabled
    sig { returns(T.nilable(String)) }
    attr_reader :updated_at
    sig { returns(T.nilable(String)) }
    attr_reader :weight_unit
    sig { returns(T.nilable(String)) }
    attr_reader :zip

    class << self
      sig do
        params(
          fields: T.untyped,
          session: Auth::Session,
          kwargs: T.untyped
        ).returns(T::Array[Shop])
      end
      def all(
        fields: nil,
        session: ShopifyAPI::Context.active_session,
        **kwargs
      )
        response = base_find(
          session: session,
          ids: {},
          params: {fields: fields}.merge(kwargs).compact,
        )

        T.cast(response, T::Array[Shop])
      end

      sig do
        params(
          fields: T.untyped,
          session: Auth::Session,
        ).returns(T.nilable(Shop))
      end
      def current(fields: nil, session: ShopifyAPI::Context.active_session)
        all(session: session, fields: fields).first
      end
    end

  end
end
