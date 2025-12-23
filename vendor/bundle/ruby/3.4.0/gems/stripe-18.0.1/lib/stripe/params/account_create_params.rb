# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountCreateParams < ::Stripe::RequestParams
    class BankAccount < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # The name of the person or business that owns the bank account.This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_name
      # The type of entity that holds the account. It can be `company` or `individual`. This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_type
      # The account number for the bank account, in string form. Must be a checking account.
      attr_accessor :account_number
      # The country in which the bank account is located.
      attr_accessor :country
      # The currency the bank account is in. This must be a country/currency pairing that [Stripe supports.](docs/payouts)
      attr_accessor :currency
      # The routing number, sort code, or other country-appropriate institution number for the bank account. For US bank accounts, this is required and should be the ACH routing number, not the wire routing number. If you are providing an IBAN for `account_number`, this field is not required.
      attr_accessor :routing_number

      def initialize(
        object: nil,
        account_holder_name: nil,
        account_holder_type: nil,
        account_number: nil,
        country: nil,
        currency: nil,
        routing_number: nil
      )
        @object = object
        @account_holder_name = account_holder_name
        @account_holder_type = account_holder_type
        @account_number = account_number
        @country = country
        @currency = currency
        @routing_number = routing_number
      end
    end

    class BusinessProfile < ::Stripe::RequestParams
      class AnnualRevenue < ::Stripe::RequestParams
        # A non-negative integer representing the amount in the [smallest currency unit](/currencies#zero-decimal).
        attr_accessor :amount
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # The close-out date of the preceding fiscal year in ISO 8601 format. E.g. 2023-12-31 for the 31st of December, 2023.
        attr_accessor :fiscal_year_end

        def initialize(amount: nil, currency: nil, fiscal_year_end: nil)
          @amount = amount
          @currency = currency
          @fiscal_year_end = fiscal_year_end
        end
      end

      class MonthlyEstimatedRevenue < ::Stripe::RequestParams
        # A non-negative integer representing how much to charge in the [smallest currency unit](/currencies#zero-decimal).
        attr_accessor :amount
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency

        def initialize(amount: nil, currency: nil)
          @amount = amount
          @currency = currency
        end
      end

      class SupportAddress < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end
      # The applicant's gross annual revenue for its preceding fiscal year.
      attr_accessor :annual_revenue
      # An estimated upper bound of employees, contractors, vendors, etc. currently working for the business.
      attr_accessor :estimated_worker_count
      # [The merchant category code for the account](/connect/setting-mcc). MCCs are used to classify businesses based on the goods or services they provide.
      attr_accessor :mcc
      # Whether the business is a minority-owned, women-owned, and/or LGBTQI+ -owned business.
      attr_accessor :minority_owned_business_designation
      # An estimate of the monthly revenue of the business. Only accepted for accounts in Brazil and India.
      attr_accessor :monthly_estimated_revenue
      # The customer-facing business name.
      attr_accessor :name
      # Internal-only description of the product sold by, or service provided by, the business. Used by Stripe for risk and underwriting purposes.
      attr_accessor :product_description
      # A publicly available mailing address for sending support issues to.
      attr_accessor :support_address
      # A publicly available email address for sending support issues to.
      attr_accessor :support_email
      # A publicly available phone number to call with support issues.
      attr_accessor :support_phone
      # A publicly available website for handling support issues.
      attr_accessor :support_url
      # The business's publicly available website.
      attr_accessor :url

      def initialize(
        annual_revenue: nil,
        estimated_worker_count: nil,
        mcc: nil,
        minority_owned_business_designation: nil,
        monthly_estimated_revenue: nil,
        name: nil,
        product_description: nil,
        support_address: nil,
        support_email: nil,
        support_phone: nil,
        support_url: nil,
        url: nil
      )
        @annual_revenue = annual_revenue
        @estimated_worker_count = estimated_worker_count
        @mcc = mcc
        @minority_owned_business_designation = minority_owned_business_designation
        @monthly_estimated_revenue = monthly_estimated_revenue
        @name = name
        @product_description = product_description
        @support_address = support_address
        @support_email = support_email
        @support_phone = support_phone
        @support_url = support_url
        @url = url
      end
    end

    class Capabilities < ::Stripe::RequestParams
      class AcssDebitPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class AffirmPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class AfterpayClearpayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class AlmaPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class AmazonPayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class AuBecsDebitPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BacsDebitPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BancontactPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BilliePayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BlikPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class BoletoPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class CardIssuing < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class CardPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class CartesBancairesPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class CashappPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class CryptoPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class EpsPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class FpxPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class GbBankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class GiropayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class GrabpayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class IdealPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class IndiaInternationalPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class JcbPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class JpBankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class KakaoPayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class KlarnaPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class KonbiniPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class KrCardPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class LegacyPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class LinkPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class MbWayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class MobilepayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class MultibancoPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class MxBankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class NaverPayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class NzBankAccountBecsDebitPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class OxxoPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class P24Payments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class PayByBankPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class PaycoPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class PaynowPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class PixPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class PromptpayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class RevolutPayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SamsungPayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SatispayPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SepaBankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SepaDebitPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SofortPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class SwishPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class TaxReportingUs1099K < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class TaxReportingUs1099Misc < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class Transfers < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class Treasury < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class TwintPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class UsBankAccountAchPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class UsBankTransferPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end

      class ZipPayments < ::Stripe::RequestParams
        # Passing true requests the capability for the account, if it is not already requested. A requested capability may not immediately become active. Any requirements to activate the capability are returned in the `requirements` arrays.
        attr_accessor :requested

        def initialize(requested: nil)
          @requested = requested
        end
      end
      # The acss_debit_payments capability.
      attr_accessor :acss_debit_payments
      # The affirm_payments capability.
      attr_accessor :affirm_payments
      # The afterpay_clearpay_payments capability.
      attr_accessor :afterpay_clearpay_payments
      # The alma_payments capability.
      attr_accessor :alma_payments
      # The amazon_pay_payments capability.
      attr_accessor :amazon_pay_payments
      # The au_becs_debit_payments capability.
      attr_accessor :au_becs_debit_payments
      # The bacs_debit_payments capability.
      attr_accessor :bacs_debit_payments
      # The bancontact_payments capability.
      attr_accessor :bancontact_payments
      # The bank_transfer_payments capability.
      attr_accessor :bank_transfer_payments
      # The billie_payments capability.
      attr_accessor :billie_payments
      # The blik_payments capability.
      attr_accessor :blik_payments
      # The boleto_payments capability.
      attr_accessor :boleto_payments
      # The card_issuing capability.
      attr_accessor :card_issuing
      # The card_payments capability.
      attr_accessor :card_payments
      # The cartes_bancaires_payments capability.
      attr_accessor :cartes_bancaires_payments
      # The cashapp_payments capability.
      attr_accessor :cashapp_payments
      # The crypto_payments capability.
      attr_accessor :crypto_payments
      # The eps_payments capability.
      attr_accessor :eps_payments
      # The fpx_payments capability.
      attr_accessor :fpx_payments
      # The gb_bank_transfer_payments capability.
      attr_accessor :gb_bank_transfer_payments
      # The giropay_payments capability.
      attr_accessor :giropay_payments
      # The grabpay_payments capability.
      attr_accessor :grabpay_payments
      # The ideal_payments capability.
      attr_accessor :ideal_payments
      # The india_international_payments capability.
      attr_accessor :india_international_payments
      # The jcb_payments capability.
      attr_accessor :jcb_payments
      # The jp_bank_transfer_payments capability.
      attr_accessor :jp_bank_transfer_payments
      # The kakao_pay_payments capability.
      attr_accessor :kakao_pay_payments
      # The klarna_payments capability.
      attr_accessor :klarna_payments
      # The konbini_payments capability.
      attr_accessor :konbini_payments
      # The kr_card_payments capability.
      attr_accessor :kr_card_payments
      # The legacy_payments capability.
      attr_accessor :legacy_payments
      # The link_payments capability.
      attr_accessor :link_payments
      # The mb_way_payments capability.
      attr_accessor :mb_way_payments
      # The mobilepay_payments capability.
      attr_accessor :mobilepay_payments
      # The multibanco_payments capability.
      attr_accessor :multibanco_payments
      # The mx_bank_transfer_payments capability.
      attr_accessor :mx_bank_transfer_payments
      # The naver_pay_payments capability.
      attr_accessor :naver_pay_payments
      # The nz_bank_account_becs_debit_payments capability.
      attr_accessor :nz_bank_account_becs_debit_payments
      # The oxxo_payments capability.
      attr_accessor :oxxo_payments
      # The p24_payments capability.
      attr_accessor :p24_payments
      # The pay_by_bank_payments capability.
      attr_accessor :pay_by_bank_payments
      # The payco_payments capability.
      attr_accessor :payco_payments
      # The paynow_payments capability.
      attr_accessor :paynow_payments
      # The pix_payments capability.
      attr_accessor :pix_payments
      # The promptpay_payments capability.
      attr_accessor :promptpay_payments
      # The revolut_pay_payments capability.
      attr_accessor :revolut_pay_payments
      # The samsung_pay_payments capability.
      attr_accessor :samsung_pay_payments
      # The satispay_payments capability.
      attr_accessor :satispay_payments
      # The sepa_bank_transfer_payments capability.
      attr_accessor :sepa_bank_transfer_payments
      # The sepa_debit_payments capability.
      attr_accessor :sepa_debit_payments
      # The sofort_payments capability.
      attr_accessor :sofort_payments
      # The swish_payments capability.
      attr_accessor :swish_payments
      # The tax_reporting_us_1099_k capability.
      attr_accessor :tax_reporting_us_1099_k
      # The tax_reporting_us_1099_misc capability.
      attr_accessor :tax_reporting_us_1099_misc
      # The transfers capability.
      attr_accessor :transfers
      # The treasury capability.
      attr_accessor :treasury
      # The twint_payments capability.
      attr_accessor :twint_payments
      # The us_bank_account_ach_payments capability.
      attr_accessor :us_bank_account_ach_payments
      # The us_bank_transfer_payments capability.
      attr_accessor :us_bank_transfer_payments
      # The zip_payments capability.
      attr_accessor :zip_payments

      def initialize(
        acss_debit_payments: nil,
        affirm_payments: nil,
        afterpay_clearpay_payments: nil,
        alma_payments: nil,
        amazon_pay_payments: nil,
        au_becs_debit_payments: nil,
        bacs_debit_payments: nil,
        bancontact_payments: nil,
        bank_transfer_payments: nil,
        billie_payments: nil,
        blik_payments: nil,
        boleto_payments: nil,
        card_issuing: nil,
        card_payments: nil,
        cartes_bancaires_payments: nil,
        cashapp_payments: nil,
        crypto_payments: nil,
        eps_payments: nil,
        fpx_payments: nil,
        gb_bank_transfer_payments: nil,
        giropay_payments: nil,
        grabpay_payments: nil,
        ideal_payments: nil,
        india_international_payments: nil,
        jcb_payments: nil,
        jp_bank_transfer_payments: nil,
        kakao_pay_payments: nil,
        klarna_payments: nil,
        konbini_payments: nil,
        kr_card_payments: nil,
        legacy_payments: nil,
        link_payments: nil,
        mb_way_payments: nil,
        mobilepay_payments: nil,
        multibanco_payments: nil,
        mx_bank_transfer_payments: nil,
        naver_pay_payments: nil,
        nz_bank_account_becs_debit_payments: nil,
        oxxo_payments: nil,
        p24_payments: nil,
        pay_by_bank_payments: nil,
        payco_payments: nil,
        paynow_payments: nil,
        pix_payments: nil,
        promptpay_payments: nil,
        revolut_pay_payments: nil,
        samsung_pay_payments: nil,
        satispay_payments: nil,
        sepa_bank_transfer_payments: nil,
        sepa_debit_payments: nil,
        sofort_payments: nil,
        swish_payments: nil,
        tax_reporting_us_1099_k: nil,
        tax_reporting_us_1099_misc: nil,
        transfers: nil,
        treasury: nil,
        twint_payments: nil,
        us_bank_account_ach_payments: nil,
        us_bank_transfer_payments: nil,
        zip_payments: nil
      )
        @acss_debit_payments = acss_debit_payments
        @affirm_payments = affirm_payments
        @afterpay_clearpay_payments = afterpay_clearpay_payments
        @alma_payments = alma_payments
        @amazon_pay_payments = amazon_pay_payments
        @au_becs_debit_payments = au_becs_debit_payments
        @bacs_debit_payments = bacs_debit_payments
        @bancontact_payments = bancontact_payments
        @bank_transfer_payments = bank_transfer_payments
        @billie_payments = billie_payments
        @blik_payments = blik_payments
        @boleto_payments = boleto_payments
        @card_issuing = card_issuing
        @card_payments = card_payments
        @cartes_bancaires_payments = cartes_bancaires_payments
        @cashapp_payments = cashapp_payments
        @crypto_payments = crypto_payments
        @eps_payments = eps_payments
        @fpx_payments = fpx_payments
        @gb_bank_transfer_payments = gb_bank_transfer_payments
        @giropay_payments = giropay_payments
        @grabpay_payments = grabpay_payments
        @ideal_payments = ideal_payments
        @india_international_payments = india_international_payments
        @jcb_payments = jcb_payments
        @jp_bank_transfer_payments = jp_bank_transfer_payments
        @kakao_pay_payments = kakao_pay_payments
        @klarna_payments = klarna_payments
        @konbini_payments = konbini_payments
        @kr_card_payments = kr_card_payments
        @legacy_payments = legacy_payments
        @link_payments = link_payments
        @mb_way_payments = mb_way_payments
        @mobilepay_payments = mobilepay_payments
        @multibanco_payments = multibanco_payments
        @mx_bank_transfer_payments = mx_bank_transfer_payments
        @naver_pay_payments = naver_pay_payments
        @nz_bank_account_becs_debit_payments = nz_bank_account_becs_debit_payments
        @oxxo_payments = oxxo_payments
        @p24_payments = p24_payments
        @pay_by_bank_payments = pay_by_bank_payments
        @payco_payments = payco_payments
        @paynow_payments = paynow_payments
        @pix_payments = pix_payments
        @promptpay_payments = promptpay_payments
        @revolut_pay_payments = revolut_pay_payments
        @samsung_pay_payments = samsung_pay_payments
        @satispay_payments = satispay_payments
        @sepa_bank_transfer_payments = sepa_bank_transfer_payments
        @sepa_debit_payments = sepa_debit_payments
        @sofort_payments = sofort_payments
        @swish_payments = swish_payments
        @tax_reporting_us_1099_k = tax_reporting_us_1099_k
        @tax_reporting_us_1099_misc = tax_reporting_us_1099_misc
        @transfers = transfers
        @treasury = treasury
        @twint_payments = twint_payments
        @us_bank_account_ach_payments = us_bank_account_ach_payments
        @us_bank_transfer_payments = us_bank_transfer_payments
        @zip_payments = zip_payments
      end
    end

    class Card < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # Attribute for param field address_city
      attr_accessor :address_city
      # Attribute for param field address_country
      attr_accessor :address_country
      # Attribute for param field address_line1
      attr_accessor :address_line1
      # Attribute for param field address_line2
      attr_accessor :address_line2
      # Attribute for param field address_state
      attr_accessor :address_state
      # Attribute for param field address_zip
      attr_accessor :address_zip
      # Attribute for param field currency
      attr_accessor :currency
      # Attribute for param field cvc
      attr_accessor :cvc
      # Attribute for param field exp_month
      attr_accessor :exp_month
      # Attribute for param field exp_year
      attr_accessor :exp_year
      # Attribute for param field name
      attr_accessor :name
      # Attribute for param field number
      attr_accessor :number
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_accessor :metadata
      # Attribute for param field default_for_currency
      attr_accessor :default_for_currency

      def initialize(
        object: nil,
        address_city: nil,
        address_country: nil,
        address_line1: nil,
        address_line2: nil,
        address_state: nil,
        address_zip: nil,
        currency: nil,
        cvc: nil,
        exp_month: nil,
        exp_year: nil,
        name: nil,
        number: nil,
        metadata: nil,
        default_for_currency: nil
      )
        @object = object
        @address_city = address_city
        @address_country = address_country
        @address_line1 = address_line1
        @address_line2 = address_line2
        @address_state = address_state
        @address_zip = address_zip
        @currency = currency
        @cvc = cvc
        @exp_month = exp_month
        @exp_year = exp_year
        @name = name
        @number = number
        @metadata = metadata
        @default_for_currency = default_for_currency
      end
    end

    class CardToken < ::Stripe::RequestParams
      # Attribute for param field object
      attr_accessor :object
      # Attribute for param field currency
      attr_accessor :currency
      # Attribute for param field token
      attr_accessor :token

      def initialize(object: nil, currency: nil, token: nil)
        @object = object
        @currency = currency
        @token = token
      end
    end

    class Company < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class AddressKana < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class AddressKanji < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class DirectorshipDeclaration < ::Stripe::RequestParams
        # The Unix timestamp marking when the directorship declaration attestation was made.
        attr_accessor :date
        # The IP address from which the directorship declaration attestation was made.
        attr_accessor :ip
        # The user agent of the browser from which the directorship declaration attestation was made.
        attr_accessor :user_agent

        def initialize(date: nil, ip: nil, user_agent: nil)
          @date = date
          @ip = ip
          @user_agent = user_agent
        end
      end

      class OwnershipDeclaration < ::Stripe::RequestParams
        # The Unix timestamp marking when the beneficial owner attestation was made.
        attr_accessor :date
        # The IP address from which the beneficial owner attestation was made.
        attr_accessor :ip
        # The user agent of the browser from which the beneficial owner attestation was made.
        attr_accessor :user_agent

        def initialize(date: nil, ip: nil, user_agent: nil)
          @date = date
          @ip = ip
          @user_agent = user_agent
        end
      end

      class RegistrationDate < ::Stripe::RequestParams
        # The day of registration, between 1 and 31.
        attr_accessor :day
        # The month of registration, between 1 and 12.
        attr_accessor :month
        # The four-digit year of registration.
        attr_accessor :year

        def initialize(day: nil, month: nil, year: nil)
          @day = day
          @month = month
          @year = year
        end
      end

      class RepresentativeDeclaration < ::Stripe::RequestParams
        # The Unix timestamp marking when the representative declaration attestation was made.
        attr_accessor :date
        # The IP address from which the representative declaration attestation was made.
        attr_accessor :ip
        # The user agent of the browser from which the representative declaration attestation was made.
        attr_accessor :user_agent

        def initialize(date: nil, ip: nil, user_agent: nil)
          @date = date
          @ip = ip
          @user_agent = user_agent
        end
      end

      class Verification < ::Stripe::RequestParams
        class Document < ::Stripe::RequestParams
          # The back of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `additional_verification`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :back
          # The front of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `additional_verification`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :front

          def initialize(back: nil, front: nil)
            @back = back
            @front = front
          end
        end
        # A document verifying the business.
        attr_accessor :document

        def initialize(document: nil)
          @document = document
        end
      end
      # The company's primary address.
      attr_accessor :address
      # The Kana variation of the company's primary address (Japan only).
      attr_accessor :address_kana
      # The Kanji variation of the company's primary address (Japan only).
      attr_accessor :address_kanji
      # Whether the company's directors have been provided. Set this Boolean to `true` after creating all the company's directors with [the Persons API](/api/persons) for accounts with a `relationship.director` requirement. This value is not automatically set to `true` after creating directors, so it needs to be updated to indicate all directors have been provided.
      attr_accessor :directors_provided
      # This hash is used to attest that the directors information provided to Stripe is both current and correct.
      attr_accessor :directorship_declaration
      # Whether the company's executives have been provided. Set this Boolean to `true` after creating all the company's executives with [the Persons API](/api/persons) for accounts with a `relationship.executive` requirement.
      attr_accessor :executives_provided
      # The export license ID number of the company, also referred as Import Export Code (India only).
      attr_accessor :export_license_id
      # The purpose code to use for export transactions (India only).
      attr_accessor :export_purpose_code
      # The company's legal name.
      attr_accessor :name
      # The Kana variation of the company's legal name (Japan only).
      attr_accessor :name_kana
      # The Kanji variation of the company's legal name (Japan only).
      attr_accessor :name_kanji
      # Whether the company's owners have been provided. Set this Boolean to `true` after creating all the company's owners with [the Persons API](/api/persons) for accounts with a `relationship.owner` requirement.
      attr_accessor :owners_provided
      # This hash is used to attest that the beneficial owner information provided to Stripe is both current and correct.
      attr_accessor :ownership_declaration
      # This value is used to determine if a business is exempt from providing ultimate beneficial owners. See [this support article](https://support.stripe.com/questions/exemption-from-providing-ownership-details) and [changelog](https://docs.stripe.com/changelog/acacia/2025-01-27/ownership-exemption-reason-accounts-api) for more details.
      attr_accessor :ownership_exemption_reason
      # The company's phone number (used for verification).
      attr_accessor :phone
      # When the business was incorporated or registered.
      attr_accessor :registration_date
      # The identification number given to a company when it is registered or incorporated, if distinct from the identification number used for filing taxes. (Examples are the CIN for companies and LLP IN for partnerships in India, and the Company Registration Number in Hong Kong).
      attr_accessor :registration_number
      # This hash is used to attest that the representative is authorized to act as the representative of their legal entity.
      attr_accessor :representative_declaration
      # The category identifying the legal structure of the company or legal entity. See [Business structure](/connect/identity-verification#business-structure) for more details. Pass an empty string to unset this value.
      attr_accessor :structure
      # The business ID number of the company, as appropriate for the company’s country. (Examples are an Employer ID Number in the U.S., a Business Number in Canada, or a Company Number in the UK.)
      attr_accessor :tax_id
      # The jurisdiction in which the `tax_id` is registered (Germany-based companies only).
      attr_accessor :tax_id_registrar
      # The VAT number of the company.
      attr_accessor :vat_id
      # Information on the verification state of the company.
      attr_accessor :verification

      def initialize(
        address: nil,
        address_kana: nil,
        address_kanji: nil,
        directors_provided: nil,
        directorship_declaration: nil,
        executives_provided: nil,
        export_license_id: nil,
        export_purpose_code: nil,
        name: nil,
        name_kana: nil,
        name_kanji: nil,
        owners_provided: nil,
        ownership_declaration: nil,
        ownership_exemption_reason: nil,
        phone: nil,
        registration_date: nil,
        registration_number: nil,
        representative_declaration: nil,
        structure: nil,
        tax_id: nil,
        tax_id_registrar: nil,
        vat_id: nil,
        verification: nil
      )
        @address = address
        @address_kana = address_kana
        @address_kanji = address_kanji
        @directors_provided = directors_provided
        @directorship_declaration = directorship_declaration
        @executives_provided = executives_provided
        @export_license_id = export_license_id
        @export_purpose_code = export_purpose_code
        @name = name
        @name_kana = name_kana
        @name_kanji = name_kanji
        @owners_provided = owners_provided
        @ownership_declaration = ownership_declaration
        @ownership_exemption_reason = ownership_exemption_reason
        @phone = phone
        @registration_date = registration_date
        @registration_number = registration_number
        @representative_declaration = representative_declaration
        @structure = structure
        @tax_id = tax_id
        @tax_id_registrar = tax_id_registrar
        @vat_id = vat_id
        @verification = verification
      end
    end

    class Controller < ::Stripe::RequestParams
      class Fees < ::Stripe::RequestParams
        # A value indicating the responsible payer of Stripe fees on this account. Defaults to `account`. Learn more about [fee behavior on connected accounts](https://docs.stripe.com/connect/direct-charges-fee-payer-behavior).
        attr_accessor :payer

        def initialize(payer: nil)
          @payer = payer
        end
      end

      class Losses < ::Stripe::RequestParams
        # A value indicating who is liable when this account can't pay back negative balances resulting from payments. Defaults to `stripe`.
        attr_accessor :payments

        def initialize(payments: nil)
          @payments = payments
        end
      end

      class StripeDashboard < ::Stripe::RequestParams
        # Whether this account should have access to the full Stripe Dashboard (`full`), to the Express Dashboard (`express`), or to no Stripe-hosted dashboard (`none`). Defaults to `full`.
        attr_accessor :type

        def initialize(type: nil)
          @type = type
        end
      end
      # A hash of configuration for who pays Stripe fees for product usage on this account.
      attr_accessor :fees
      # A hash of configuration for products that have negative balance liability, and whether Stripe or a Connect application is responsible for them.
      attr_accessor :losses
      # A value indicating responsibility for collecting updated information when requirements on the account are due or change. Defaults to `stripe`.
      attr_accessor :requirement_collection
      # A hash of configuration for Stripe-hosted dashboards.
      attr_accessor :stripe_dashboard

      def initialize(fees: nil, losses: nil, requirement_collection: nil, stripe_dashboard: nil)
        @fees = fees
        @losses = losses
        @requirement_collection = requirement_collection
        @stripe_dashboard = stripe_dashboard
      end
    end

    class Documents < ::Stripe::RequestParams
      class BankAccountOwnershipVerification < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class CompanyLicense < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class CompanyMemorandumOfAssociation < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class CompanyMinisterialDecree < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class CompanyRegistrationVerification < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class CompanyTaxIdVerification < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class ProofOfAddress < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class ProofOfRegistration < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end

      class ProofOfUltimateBeneficialOwnership < ::Stripe::RequestParams
        # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
        attr_accessor :files

        def initialize(files: nil)
          @files = files
        end
      end
      # One or more documents that support the [Bank account ownership verification](https://support.stripe.com/questions/bank-account-ownership-verification) requirement. Must be a document associated with the account’s primary active bank account that displays the last 4 digits of the account number, either a statement or a check.
      attr_accessor :bank_account_ownership_verification
      # One or more documents that demonstrate proof of a company's license to operate.
      attr_accessor :company_license
      # One or more documents showing the company's Memorandum of Association.
      attr_accessor :company_memorandum_of_association
      # (Certain countries only) One or more documents showing the ministerial decree legalizing the company's establishment.
      attr_accessor :company_ministerial_decree
      # One or more documents that demonstrate proof of a company's registration with the appropriate local authorities.
      attr_accessor :company_registration_verification
      # One or more documents that demonstrate proof of a company's tax ID.
      attr_accessor :company_tax_id_verification
      # One or more documents that demonstrate proof of address.
      attr_accessor :proof_of_address
      # One or more documents showing the company’s proof of registration with the national business registry.
      attr_accessor :proof_of_registration
      # One or more documents that demonstrate proof of ultimate beneficial ownership.
      attr_accessor :proof_of_ultimate_beneficial_ownership

      def initialize(
        bank_account_ownership_verification: nil,
        company_license: nil,
        company_memorandum_of_association: nil,
        company_ministerial_decree: nil,
        company_registration_verification: nil,
        company_tax_id_verification: nil,
        proof_of_address: nil,
        proof_of_registration: nil,
        proof_of_ultimate_beneficial_ownership: nil
      )
        @bank_account_ownership_verification = bank_account_ownership_verification
        @company_license = company_license
        @company_memorandum_of_association = company_memorandum_of_association
        @company_ministerial_decree = company_ministerial_decree
        @company_registration_verification = company_registration_verification
        @company_tax_id_verification = company_tax_id_verification
        @proof_of_address = proof_of_address
        @proof_of_registration = proof_of_registration
        @proof_of_ultimate_beneficial_ownership = proof_of_ultimate_beneficial_ownership
      end
    end

    class Groups < ::Stripe::RequestParams
      # The group the account is in to determine their payments pricing, and null if the account is on customized pricing. [See the Platform pricing tool documentation](https://stripe.com/docs/connect/platform-pricing-tools) for details.
      attr_accessor :payments_pricing

      def initialize(payments_pricing: nil)
        @payments_pricing = payments_pricing
      end
    end

    class Individual < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class AddressKana < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class AddressKanji < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class Dob < ::Stripe::RequestParams
        # The day of birth, between 1 and 31.
        attr_accessor :day
        # The month of birth, between 1 and 12.
        attr_accessor :month
        # The four-digit year of birth.
        attr_accessor :year

        def initialize(day: nil, month: nil, year: nil)
          @day = day
          @month = month
          @year = year
        end
      end

      class RegisteredAddress < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class Relationship < ::Stripe::RequestParams
        # Whether the person is a director of the account's legal entity. Directors are typically members of the governing board of the company, or responsible for ensuring the company meets its regulatory obligations.
        attr_accessor :director
        # Whether the person has significant responsibility to control, manage, or direct the organization.
        attr_accessor :executive
        # Whether the person is an owner of the account’s legal entity.
        attr_accessor :owner
        # The percent owned by the person of the account's legal entity.
        attr_accessor :percent_ownership
        # The person's title (e.g., CEO, Support Engineer).
        attr_accessor :title

        def initialize(
          director: nil,
          executive: nil,
          owner: nil,
          percent_ownership: nil,
          title: nil
        )
          @director = director
          @executive = executive
          @owner = owner
          @percent_ownership = percent_ownership
          @title = title
        end
      end

      class Verification < ::Stripe::RequestParams
        class AdditionalDocument < ::Stripe::RequestParams
          # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :back
          # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :front

          def initialize(back: nil, front: nil)
            @back = back
            @front = front
          end
        end

        class Document < ::Stripe::RequestParams
          # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :back
          # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :front

          def initialize(back: nil, front: nil)
            @back = back
            @front = front
          end
        end
        # A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
        attr_accessor :additional_document
        # An identifying document, either a passport or local ID card.
        attr_accessor :document

        def initialize(additional_document: nil, document: nil)
          @additional_document = additional_document
          @document = document
        end
      end
      # The individual's primary address.
      attr_accessor :address
      # The Kana variation of the individual's primary address (Japan only).
      attr_accessor :address_kana
      # The Kanji variation of the individual's primary address (Japan only).
      attr_accessor :address_kanji
      # The individual's date of birth.
      attr_accessor :dob
      # The individual's email address.
      attr_accessor :email
      # The individual's first name.
      attr_accessor :first_name
      # The Kana variation of the individual's first name (Japan only).
      attr_accessor :first_name_kana
      # The Kanji variation of the individual's first name (Japan only).
      attr_accessor :first_name_kanji
      # A list of alternate names or aliases that the individual is known by.
      attr_accessor :full_name_aliases
      # The individual's gender
      attr_accessor :gender
      # The government-issued ID number of the individual, as appropriate for the representative's country. (Examples are a Social Security Number in the U.S., or a Social Insurance Number in Canada). Instead of the number itself, you can also provide a [PII token created with Stripe.js](/js/tokens/create_token?type=pii).
      attr_accessor :id_number
      # The government-issued secondary ID number of the individual, as appropriate for the representative's country, will be used for enhanced verification checks. In Thailand, this would be the laser code found on the back of an ID card. Instead of the number itself, you can also provide a [PII token created with Stripe.js](/js/tokens/create_token?type=pii).
      attr_accessor :id_number_secondary
      # The individual's last name.
      attr_accessor :last_name
      # The Kana variation of the individual's last name (Japan only).
      attr_accessor :last_name_kana
      # The Kanji variation of the individual's last name (Japan only).
      attr_accessor :last_name_kanji
      # The individual's maiden name.
      attr_accessor :maiden_name
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The individual's phone number.
      attr_accessor :phone
      # Indicates if the person or any of their representatives, family members, or other closely related persons, declares that they hold or have held an important public job or function, in any jurisdiction.
      attr_accessor :political_exposure
      # The individual's registered address.
      attr_accessor :registered_address
      # Describes the person’s relationship to the account.
      attr_accessor :relationship
      # The last four digits of the individual's Social Security Number (U.S. only).
      attr_accessor :ssn_last_4
      # The individual's verification document information.
      attr_accessor :verification

      def initialize(
        address: nil,
        address_kana: nil,
        address_kanji: nil,
        dob: nil,
        email: nil,
        first_name: nil,
        first_name_kana: nil,
        first_name_kanji: nil,
        full_name_aliases: nil,
        gender: nil,
        id_number: nil,
        id_number_secondary: nil,
        last_name: nil,
        last_name_kana: nil,
        last_name_kanji: nil,
        maiden_name: nil,
        metadata: nil,
        phone: nil,
        political_exposure: nil,
        registered_address: nil,
        relationship: nil,
        ssn_last_4: nil,
        verification: nil
      )
        @address = address
        @address_kana = address_kana
        @address_kanji = address_kanji
        @dob = dob
        @email = email
        @first_name = first_name
        @first_name_kana = first_name_kana
        @first_name_kanji = first_name_kanji
        @full_name_aliases = full_name_aliases
        @gender = gender
        @id_number = id_number
        @id_number_secondary = id_number_secondary
        @last_name = last_name
        @last_name_kana = last_name_kana
        @last_name_kanji = last_name_kanji
        @maiden_name = maiden_name
        @metadata = metadata
        @phone = phone
        @political_exposure = political_exposure
        @registered_address = registered_address
        @relationship = relationship
        @ssn_last_4 = ssn_last_4
        @verification = verification
      end
    end

    class Settings < ::Stripe::RequestParams
      class BacsDebitPayments < ::Stripe::RequestParams
        # The Bacs Direct Debit Display Name for this account. For payments made with Bacs Direct Debit, this name appears on the mandate as the statement descriptor. Mobile banking apps display it as the name of the business. To use custom branding, set the Bacs Direct Debit Display Name during or right after creation. Custom branding incurs an additional monthly fee for the platform. If you don't set the display name before requesting Bacs capability, it's automatically set as "Stripe" and the account is onboarded to Stripe branding, which is free.
        attr_accessor :display_name

        def initialize(display_name: nil)
          @display_name = display_name
        end
      end

      class Branding < ::Stripe::RequestParams
        # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) An icon for the account. Must be square and at least 128px x 128px.
        attr_accessor :icon
        # (ID of a [file upload](https://stripe.com/docs/guides/file-upload)) A logo for the account that will be used in Checkout instead of the icon and without the account's name next to it if provided. Must be at least 128px x 128px.
        attr_accessor :logo
        # A CSS hex color value representing the primary branding color for this account.
        attr_accessor :primary_color
        # A CSS hex color value representing the secondary branding color for this account.
        attr_accessor :secondary_color

        def initialize(icon: nil, logo: nil, primary_color: nil, secondary_color: nil)
          @icon = icon
          @logo = logo
          @primary_color = primary_color
          @secondary_color = secondary_color
        end
      end

      class CardIssuing < ::Stripe::RequestParams
        class TosAcceptance < ::Stripe::RequestParams
          # The Unix timestamp marking when the account representative accepted the service agreement.
          attr_accessor :date
          # The IP address from which the account representative accepted the service agreement.
          attr_accessor :ip
          # The user agent of the browser from which the account representative accepted the service agreement.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end
        # Details on the account's acceptance of the [Stripe Issuing Terms and Disclosures](/issuing/connect/tos_acceptance).
        attr_accessor :tos_acceptance

        def initialize(tos_acceptance: nil)
          @tos_acceptance = tos_acceptance
        end
      end

      class CardPayments < ::Stripe::RequestParams
        class DeclineOn < ::Stripe::RequestParams
          # Whether Stripe automatically declines charges with an incorrect ZIP or postal code. This setting only applies when a ZIP or postal code is provided and they fail bank verification.
          attr_accessor :avs_failure
          # Whether Stripe automatically declines charges with an incorrect CVC. This setting only applies when a CVC is provided and it fails bank verification.
          attr_accessor :cvc_failure

          def initialize(avs_failure: nil, cvc_failure: nil)
            @avs_failure = avs_failure
            @cvc_failure = cvc_failure
          end
        end
        # Automatically declines certain charge types regardless of whether the card issuer accepted or declined the charge.
        attr_accessor :decline_on
        # The default text that appears on credit card statements when a charge is made. This field prefixes any dynamic `statement_descriptor` specified on the charge. `statement_descriptor_prefix` is useful for maximizing descriptor space for the dynamic portion.
        attr_accessor :statement_descriptor_prefix
        # The Kana variation of the default text that appears on credit card statements when a charge is made (Japan only). This field prefixes any dynamic `statement_descriptor_suffix_kana` specified on the charge. `statement_descriptor_prefix_kana` is useful for maximizing descriptor space for the dynamic portion.
        attr_accessor :statement_descriptor_prefix_kana
        # The Kanji variation of the default text that appears on credit card statements when a charge is made (Japan only). This field prefixes any dynamic `statement_descriptor_suffix_kanji` specified on the charge. `statement_descriptor_prefix_kanji` is useful for maximizing descriptor space for the dynamic portion.
        attr_accessor :statement_descriptor_prefix_kanji

        def initialize(
          decline_on: nil,
          statement_descriptor_prefix: nil,
          statement_descriptor_prefix_kana: nil,
          statement_descriptor_prefix_kanji: nil
        )
          @decline_on = decline_on
          @statement_descriptor_prefix = statement_descriptor_prefix
          @statement_descriptor_prefix_kana = statement_descriptor_prefix_kana
          @statement_descriptor_prefix_kanji = statement_descriptor_prefix_kanji
        end
      end

      class Invoices < ::Stripe::RequestParams
        # Whether to save the payment method after a payment is completed for a one-time invoice or a subscription invoice when the customer already has a default payment method on the hosted invoice page.
        attr_accessor :hosted_payment_method_save

        def initialize(hosted_payment_method_save: nil)
          @hosted_payment_method_save = hosted_payment_method_save
        end
      end

      class Payments < ::Stripe::RequestParams
        # The default text that appears on statements for non-card charges outside of Japan. For card charges, if you don't set a `statement_descriptor_prefix`, this text is also used as the statement descriptor prefix. In that case, if concatenating the statement descriptor suffix causes the combined statement descriptor to exceed 22 characters, we truncate the `statement_descriptor` text to limit the full descriptor to 22 characters. For more information about statement descriptors and their requirements, see the [account settings documentation](https://docs.stripe.com/get-started/account/statement-descriptors).
        attr_accessor :statement_descriptor
        # The Kana variation of `statement_descriptor` used for charges in Japan. Japanese statement descriptors have [special requirements](https://docs.stripe.com/get-started/account/statement-descriptors#set-japanese-statement-descriptors).
        attr_accessor :statement_descriptor_kana
        # The Kanji variation of `statement_descriptor` used for charges in Japan. Japanese statement descriptors have [special requirements](https://docs.stripe.com/get-started/account/statement-descriptors#set-japanese-statement-descriptors).
        attr_accessor :statement_descriptor_kanji

        def initialize(
          statement_descriptor: nil,
          statement_descriptor_kana: nil,
          statement_descriptor_kanji: nil
        )
          @statement_descriptor = statement_descriptor
          @statement_descriptor_kana = statement_descriptor_kana
          @statement_descriptor_kanji = statement_descriptor_kanji
        end
      end

      class Payouts < ::Stripe::RequestParams
        class Schedule < ::Stripe::RequestParams
          # The number of days charge funds are held before being paid out. May also be set to `minimum`, representing the lowest available value for the account country. Default is `minimum`. The `delay_days` parameter remains at the last configured value if `interval` is `manual`. [Learn more about controlling payout delay days](/connect/manage-payout-schedule).
          attr_accessor :delay_days
          # How frequently available funds are paid out. One of: `daily`, `manual`, `weekly`, or `monthly`. Default is `daily`.
          attr_accessor :interval
          # The day of the month when available funds are paid out, specified as a number between 1--31. Payouts nominally scheduled between the 29th and 31st of the month are instead sent on the last day of a shorter month. Required and applicable only if `interval` is `monthly`.
          attr_accessor :monthly_anchor
          # The days of the month when available funds are paid out, specified as an array of numbers between 1--31. Payouts nominally scheduled between the 29th and 31st of the month are instead sent on the last day of a shorter month. Required and applicable only if `interval` is `monthly` and `monthly_anchor` is not set.
          attr_accessor :monthly_payout_days
          # The day of the week when available funds are paid out, specified as `monday`, `tuesday`, etc. Required and applicable only if `interval` is `weekly`.
          attr_accessor :weekly_anchor
          # The days of the week when available funds are paid out, specified as an array, e.g., [`monday`, `tuesday`]. Required and applicable only if `interval` is `weekly`.
          attr_accessor :weekly_payout_days

          def initialize(
            delay_days: nil,
            interval: nil,
            monthly_anchor: nil,
            monthly_payout_days: nil,
            weekly_anchor: nil,
            weekly_payout_days: nil
          )
            @delay_days = delay_days
            @interval = interval
            @monthly_anchor = monthly_anchor
            @monthly_payout_days = monthly_payout_days
            @weekly_anchor = weekly_anchor
            @weekly_payout_days = weekly_payout_days
          end
        end
        # A Boolean indicating whether Stripe should try to reclaim negative balances from an attached bank account. For details, see [Understanding Connect Account Balances](/connect/account-balances).
        attr_accessor :debit_negative_balances
        # Details on when funds from charges are available, and when they are paid out to an external account. For details, see our [Setting Bank and Debit Card Payouts](/connect/bank-transfers#payout-information) documentation.
        attr_accessor :schedule
        # The text that appears on the bank account statement for payouts. If not set, this defaults to the platform's bank descriptor as set in the Dashboard.
        attr_accessor :statement_descriptor

        def initialize(debit_negative_balances: nil, schedule: nil, statement_descriptor: nil)
          @debit_negative_balances = debit_negative_balances
          @schedule = schedule
          @statement_descriptor = statement_descriptor
        end
      end

      class Treasury < ::Stripe::RequestParams
        class TosAcceptance < ::Stripe::RequestParams
          # The Unix timestamp marking when the account representative accepted the service agreement.
          attr_accessor :date
          # The IP address from which the account representative accepted the service agreement.
          attr_accessor :ip
          # The user agent of the browser from which the account representative accepted the service agreement.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end
        # Details on the account's acceptance of the Stripe Treasury Services Agreement.
        attr_accessor :tos_acceptance

        def initialize(tos_acceptance: nil)
          @tos_acceptance = tos_acceptance
        end
      end
      # Settings specific to Bacs Direct Debit.
      attr_accessor :bacs_debit_payments
      # Settings used to apply the account's branding to email receipts, invoices, Checkout, and other products.
      attr_accessor :branding
      # Settings specific to the account's use of the Card Issuing product.
      attr_accessor :card_issuing
      # Settings specific to card charging on the account.
      attr_accessor :card_payments
      # Settings specific to the account’s use of Invoices.
      attr_accessor :invoices
      # Settings that apply across payment methods for charging on the account.
      attr_accessor :payments
      # Settings specific to the account's payouts.
      attr_accessor :payouts
      # Settings specific to the account's Treasury FinancialAccounts.
      attr_accessor :treasury

      def initialize(
        bacs_debit_payments: nil,
        branding: nil,
        card_issuing: nil,
        card_payments: nil,
        invoices: nil,
        payments: nil,
        payouts: nil,
        treasury: nil
      )
        @bacs_debit_payments = bacs_debit_payments
        @branding = branding
        @card_issuing = card_issuing
        @card_payments = card_payments
        @invoices = invoices
        @payments = payments
        @payouts = payouts
        @treasury = treasury
      end
    end

    class TosAcceptance < ::Stripe::RequestParams
      # The Unix timestamp marking when the account representative accepted their service agreement.
      attr_accessor :date
      # The IP address from which the account representative accepted their service agreement.
      attr_accessor :ip
      # The user's service agreement type.
      attr_accessor :service_agreement
      # The user agent of the browser from which the account representative accepted their service agreement.
      attr_accessor :user_agent

      def initialize(date: nil, ip: nil, service_agreement: nil, user_agent: nil)
        @date = date
        @ip = ip
        @service_agreement = service_agreement
        @user_agent = user_agent
      end
    end
    # An [account token](https://stripe.com/docs/api#create_account_token), used to securely provide details to the account.
    attr_accessor :account_token
    # Business information about the account.
    attr_accessor :business_profile
    # The business type. Once you create an [Account Link](/api/account_links) or [Account Session](/api/account_sessions), this property can only be updated for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts.
    attr_accessor :business_type
    # Each key of the dictionary represents a capability, and each capability
    # maps to its settings (for example, whether it has been requested or not). Each
    # capability is inactive until you have provided its specific
    # requirements and Stripe has verified them. An account might have some
    # of its requested capabilities be active and some be inactive.
    #
    # Required when [account.controller.stripe_dashboard.type](/api/accounts/create#create_account-controller-dashboard-type)
    # is `none`, which includes Custom accounts.
    attr_accessor :capabilities
    # Information about the company or business. This field is available for any `business_type`. Once you create an [Account Link](/api/account_links) or [Account Session](/api/account_sessions), this property can only be updated for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts.
    attr_accessor :company
    # A hash of configuration describing the account controller's attributes.
    attr_accessor :controller
    # The country in which the account holder resides, or in which the business is legally established. This should be an ISO 3166-1 alpha-2 country code. For example, if you are in the United States and the business for which you're creating an account is legally represented in Canada, you would use `CA` as the country for the account being created. Available countries include [Stripe's global markets](https://stripe.com/global) as well as countries where [cross-border payouts](https://stripe.com/docs/connect/cross-border-payouts) are supported.
    attr_accessor :country
    # Three-letter ISO currency code representing the default currency for the account. This must be a currency that [Stripe supports in the account's country](https://docs.stripe.com/payouts).
    attr_accessor :default_currency
    # Documents that may be submitted to satisfy various informational requests.
    attr_accessor :documents
    # The email address of the account holder. This is only to make the account easier to identify to you. If [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts, Stripe doesn't email the account without your consent.
    attr_accessor :email
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A card or bank account to attach to the account for receiving [payouts](/connect/bank-debit-card-payouts) (you won’t be able to use it for top-ups). You can provide either a token, like the ones returned by [Stripe.js](/js), or a dictionary, as documented in the `external_account` parameter for [bank account](/api#account_create_bank_account) creation. <br><br>By default, providing an external account sets it as the new default external account for its currency, and deletes the old default if one exists. To add additional external accounts without replacing the existing default for the currency, use the [bank account](/api#account_create_bank_account) or [card creation](/api#account_create_card) APIs. After you create an [Account Link](/api/account_links) or [Account Session](/api/account_sessions), this property can only be updated for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts.
    attr_accessor :external_account
    # A hash of account group type to tokens. These are account groups this account should be added to.
    attr_accessor :groups
    # Information about the person represented by the account. This field is null unless `business_type` is set to `individual`. Once you create an [Account Link](/api/account_links) or [Account Session](/api/account_sessions), this property can only be updated for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts.
    attr_accessor :individual
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Options for customizing how the account functions within Stripe.
    attr_accessor :settings
    # Details on the account's acceptance of the [Stripe Services Agreement](/connect/updating-accounts#tos-acceptance). This property can only be updated for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts. This property defaults to a `full` service agreement when empty.
    attr_accessor :tos_acceptance
    # The type of Stripe account to create. May be one of `custom`, `express` or `standard`.
    attr_accessor :type

    def initialize(
      account_token: nil,
      business_profile: nil,
      business_type: nil,
      capabilities: nil,
      company: nil,
      controller: nil,
      country: nil,
      default_currency: nil,
      documents: nil,
      email: nil,
      expand: nil,
      external_account: nil,
      groups: nil,
      individual: nil,
      metadata: nil,
      settings: nil,
      tos_acceptance: nil,
      type: nil
    )
      @account_token = account_token
      @business_profile = business_profile
      @business_type = business_type
      @capabilities = capabilities
      @company = company
      @controller = controller
      @country = country
      @default_currency = default_currency
      @documents = documents
      @email = email
      @expand = expand
      @external_account = external_account
      @groups = groups
      @individual = individual
      @metadata = metadata
      @settings = settings
      @tos_acceptance = tos_acceptance
      @type = type
    end
  end
end
