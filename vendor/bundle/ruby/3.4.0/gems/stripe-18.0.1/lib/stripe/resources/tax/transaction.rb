# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    # A Tax Transaction records the tax collected from or refunded to your customer.
    #
    # Related guide: [Calculate tax in your custom payment flow](https://stripe.com/docs/tax/custom#tax-transaction)
    class Transaction < APIResource
      OBJECT_NAME = "tax.transaction"
      def self.object_name
        "tax.transaction"
      end

      class CustomerDetails < ::Stripe::StripeObject
        class Address < ::Stripe::StripeObject
          # City, district, suburb, town, or village.
          attr_reader :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_reader :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_reader :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_reader :line2
          # ZIP or postal code.
          attr_reader :postal_code
          # State/province as an [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) subdivision code, without country prefix, such as "NY" or "TX".
          attr_reader :state

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class TaxId < ::Stripe::StripeObject
          # The type of the tax ID, one of `ad_nrt`, `ar_cuit`, `eu_vat`, `bo_tin`, `br_cnpj`, `br_cpf`, `cn_tin`, `co_nit`, `cr_tin`, `do_rcn`, `ec_ruc`, `eu_oss_vat`, `hr_oib`, `pe_ruc`, `ro_tin`, `rs_pib`, `sv_nit`, `uy_ruc`, `ve_rif`, `vn_tin`, `gb_vat`, `nz_gst`, `au_abn`, `au_arn`, `in_gst`, `no_vat`, `no_voec`, `za_vat`, `ch_vat`, `mx_rfc`, `sg_uen`, `ru_inn`, `ru_kpp`, `ca_bn`, `hk_br`, `es_cif`, `tw_vat`, `th_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `li_uid`, `li_vat`, `my_itn`, `us_ein`, `kr_brn`, `ca_qst`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `my_sst`, `sg_gst`, `ae_trn`, `cl_tin`, `sa_vat`, `id_npwp`, `my_frp`, `il_vat`, `ge_vat`, `ua_vat`, `is_vat`, `bg_uic`, `hu_tin`, `si_tin`, `ke_pin`, `tr_tin`, `eg_tin`, `ph_tin`, `al_tin`, `bh_vat`, `kz_bin`, `ng_tin`, `om_vat`, `de_stn`, `ch_uid`, `tz_vat`, `uz_vat`, `uz_tin`, `md_vat`, `ma_vat`, `by_tin`, `ao_tin`, `bs_tin`, `bb_tin`, `cd_nif`, `mr_nif`, `me_pib`, `zw_tin`, `ba_tin`, `gn_nif`, `mk_vat`, `sr_fin`, `sn_ninea`, `am_tin`, `np_pan`, `tj_tin`, `ug_tin`, `zm_tin`, `kh_tin`, `aw_tin`, `az_tin`, `bd_bin`, `bj_ifu`, `et_tin`, `kg_tin`, `la_tin`, `cm_niu`, `cv_nif`, `bf_ifu`, or `unknown`
          attr_reader :type
          # The value of the tax ID.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The customer's postal address (for example, home or business location).
        attr_reader :address
        # The type of customer address provided.
        attr_reader :address_source
        # The customer's IP address (IPv4 or IPv6).
        attr_reader :ip_address
        # The customer's tax IDs (for example, EU VAT numbers).
        attr_reader :tax_ids
        # The taxability override used for taxation.
        attr_reader :taxability_override

        def self.inner_class_types
          @inner_class_types = { address: Address, tax_ids: TaxId }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Reversal < ::Stripe::StripeObject
        # The `id` of the reversed `Transaction` object.
        attr_reader :original_transaction

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShipFromDetails < ::Stripe::StripeObject
        class Address < ::Stripe::StripeObject
          # City, district, suburb, town, or village.
          attr_reader :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_reader :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_reader :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_reader :line2
          # ZIP or postal code.
          attr_reader :postal_code
          # State/province as an [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) subdivision code, without country prefix, such as "NY" or "TX".
          attr_reader :state

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field address
        attr_reader :address

        def self.inner_class_types
          @inner_class_types = { address: Address }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShippingCost < ::Stripe::StripeObject
        class TaxBreakdown < ::Stripe::StripeObject
          class Jurisdiction < ::Stripe::StripeObject
            # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
            attr_reader :country
            # A human-readable name for the jurisdiction imposing the tax.
            attr_reader :display_name
            # Indicates the level of the jurisdiction imposing the tax.
            attr_reader :level
            # [ISO 3166-2 subdivision code](https://en.wikipedia.org/wiki/ISO_3166-2), without country prefix. For example, "NY" for New York, United States.
            attr_reader :state

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class TaxRateDetails < ::Stripe::StripeObject
            # A localized display name for tax type, intended to be human-readable. For example, "Local Sales and Use Tax", "Value-added tax (VAT)", or "Umsatzsteuer (USt.)".
            attr_reader :display_name
            # The tax rate percentage as a string. For example, 8.5% is represented as "8.5".
            attr_reader :percentage_decimal
            # The tax type, such as `vat` or `sales_tax`.
            attr_reader :tax_type

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The amount of tax, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
          attr_reader :amount
          # Attribute for field jurisdiction
          attr_reader :jurisdiction
          # Indicates whether the jurisdiction was determined by the origin (merchant's address) or destination (customer's address).
          attr_reader :sourcing
          # Details regarding the rate for this tax. This field will be `null` when the tax is not imposed, for example if the product is exempt from tax.
          attr_reader :tax_rate_details
          # The reasoning behind this tax, for example, if the product is tax exempt. The possible values for this field may be extended as new tax rules are supported.
          attr_reader :taxability_reason
          # The amount on which tax is calculated, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
          attr_reader :taxable_amount

          def self.inner_class_types
            @inner_class_types = { jurisdiction: Jurisdiction, tax_rate_details: TaxRateDetails }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The shipping amount in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). If `tax_behavior=inclusive`, then this amount includes taxes. Otherwise, taxes were calculated on top of this amount.
        attr_reader :amount
        # The amount of tax calculated for shipping, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_reader :amount_tax
        # The ID of an existing [ShippingRate](https://stripe.com/docs/api/shipping_rates/object).
        attr_reader :shipping_rate
        # Specifies whether the `amount` includes taxes. If `tax_behavior=inclusive`, then the amount includes taxes.
        attr_reader :tax_behavior
        # Detailed account of taxes relevant to shipping cost. (It is not populated for the transaction resource object and will be removed in the next API version.)
        attr_reader :tax_breakdown
        # The [tax code](https://stripe.com/docs/tax/tax-categories) ID used for shipping.
        attr_reader :tax_code

        def self.inner_class_types
          @inner_class_types = { tax_breakdown: TaxBreakdown }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # The ID of an existing [Customer](https://stripe.com/docs/api/customers/object) used for the resource.
      attr_reader :customer
      # Attribute for field customer_details
      attr_reader :customer_details
      # Unique identifier for the transaction.
      attr_reader :id
      # The tax collected or refunded, by line item.
      attr_reader :line_items
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The Unix timestamp representing when the tax liability is assumed or reduced.
      attr_reader :posted_at
      # A custom unique identifier, such as 'myOrder_123'.
      attr_reader :reference
      # If `type=reversal`, contains information about what was reversed.
      attr_reader :reversal
      # The details of the ship from location, such as the address.
      attr_reader :ship_from_details
      # The shipping cost details for the transaction.
      attr_reader :shipping_cost
      # Timestamp of date at which the tax rules and rates in effect applies for the calculation.
      attr_reader :tax_date
      # If `reversal`, this transaction reverses an earlier transaction.
      attr_reader :type

      # Creates a Tax Transaction from a calculation, if that calculation hasn't expired. Calculations expire after 90 days.
      def self.create_from_calculation(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/tax/transactions/create_from_calculation",
          params: params,
          opts: opts
        )
      end

      # Partially or fully reverses a previously created Transaction.
      def self.create_reversal(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/tax/transactions/create_reversal",
          params: params,
          opts: opts
        )
      end

      # Retrieves the line items of a committed standalone transaction as a collection.
      def list_line_items(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/tax/transactions/%<transaction>s/line_items", { transaction: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Retrieves the line items of a committed standalone transaction as a collection.
      def self.list_line_items(transaction, params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/tax/transactions/%<transaction>s/line_items", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          customer_details: CustomerDetails,
          reversal: Reversal,
          ship_from_details: ShipFromDetails,
          shipping_cost: ShippingCost,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
