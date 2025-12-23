# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerCreateParams < ::Stripe::RequestParams
    class Address < ::Stripe::RequestParams
      # City, district, suburb, town, or village.
      attr_accessor :city
      # A freeform text field for the country. However, in order to activate some tax features, the format should be a two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_accessor :country
      # Address line 1, such as the street, PO Box, or company name.
      attr_accessor :line1
      # Address line 2, such as the apartment, suite, unit, or building.
      attr_accessor :line2
      # ZIP or postal code.
      attr_accessor :postal_code
      # State, county, province, or region.
      attr_accessor :state

      def initialize(city: nil, country: nil, line1: nil, line2: nil, postal_code: nil, state: nil)
        @city = city
        @country = country
        @line1 = line1
        @line2 = line2
        @postal_code = postal_code
        @state = state
      end
    end

    class CashBalance < ::Stripe::RequestParams
      class Settings < ::Stripe::RequestParams
        # Controls how funds transferred by the customer are applied to payment intents and invoices. Valid options are `automatic`, `manual`, or `merchant_default`. For more information about these reconciliation modes, see [Reconciliation](https://stripe.com/docs/payments/customer-balance/reconciliation).
        attr_accessor :reconciliation_mode

        def initialize(reconciliation_mode: nil)
          @reconciliation_mode = reconciliation_mode
        end
      end
      # Settings controlling the behavior of the customer's cash balance,
      # such as reconciliation of funds received.
      attr_accessor :settings

      def initialize(settings: nil)
        @settings = settings
      end
    end

    class InvoiceSettings < ::Stripe::RequestParams
      class CustomField < ::Stripe::RequestParams
        # The name of the custom field. This may be up to 40 characters.
        attr_accessor :name
        # The value of the custom field. This may be up to 140 characters.
        attr_accessor :value

        def initialize(name: nil, value: nil)
          @name = name
          @value = value
        end
      end

      class RenderingOptions < ::Stripe::RequestParams
        # How line-item prices and amounts will be displayed with respect to tax on invoice PDFs. One of `exclude_tax` or `include_inclusive_tax`. `include_inclusive_tax` will include inclusive tax (and exclude exclusive tax) in invoice PDF amounts. `exclude_tax` will exclude all tax (inclusive and exclusive alike) from invoice PDF amounts.
        attr_accessor :amount_tax_display
        # ID of the invoice rendering template to use for future invoices.
        attr_accessor :template

        def initialize(amount_tax_display: nil, template: nil)
          @amount_tax_display = amount_tax_display
          @template = template
        end
      end
      # The list of up to 4 default custom fields to be displayed on invoices for this customer. When updating, pass an empty string to remove previously-defined fields.
      attr_accessor :custom_fields
      # ID of a payment method that's attached to the customer, to be used as the customer's default payment method for subscriptions and invoices.
      attr_accessor :default_payment_method
      # Default footer to be displayed on invoices for this customer.
      attr_accessor :footer
      # Default options for invoice PDF rendering for this customer.
      attr_accessor :rendering_options

      def initialize(
        custom_fields: nil,
        default_payment_method: nil,
        footer: nil,
        rendering_options: nil
      )
        @custom_fields = custom_fields
        @default_payment_method = default_payment_method
        @footer = footer
        @rendering_options = rendering_options
      end
    end

    class Shipping < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # A freeform text field for the country. However, in order to activate some tax features, the format should be a two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
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
      # Customer shipping address.
      attr_accessor :address
      # Customer name.
      attr_accessor :name
      # Customer phone (including extension).
      attr_accessor :phone

      def initialize(address: nil, name: nil, phone: nil)
        @address = address
        @name = name
        @phone = phone
      end
    end

    class Tax < ::Stripe::RequestParams
      # A recent IP address of the customer used for tax reporting and tax location inference. Stripe recommends updating the IP address when a new PaymentMethod is attached or the address field on the customer is updated. We recommend against updating this field more frequently since it could result in unexpected tax location/reporting outcomes.
      attr_accessor :ip_address
      # A flag that indicates when Stripe should validate the customer tax location. Defaults to `deferred`.
      attr_accessor :validate_location

      def initialize(ip_address: nil, validate_location: nil)
        @ip_address = ip_address
        @validate_location = validate_location
      end
    end

    class TaxIdDatum < ::Stripe::RequestParams
      # Type of the tax ID, one of `ad_nrt`, `ae_trn`, `al_tin`, `am_tin`, `ao_tin`, `ar_cuit`, `au_abn`, `au_arn`, `aw_tin`, `az_tin`, `ba_tin`, `bb_tin`, `bd_bin`, `bf_ifu`, `bg_uic`, `bh_vat`, `bj_ifu`, `bo_tin`, `br_cnpj`, `br_cpf`, `bs_tin`, `by_tin`, `ca_bn`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `ca_qst`, `cd_nif`, `ch_uid`, `ch_vat`, `cl_tin`, `cm_niu`, `cn_tin`, `co_nit`, `cr_tin`, `cv_nif`, `de_stn`, `do_rcn`, `ec_ruc`, `eg_tin`, `es_cif`, `et_tin`, `eu_oss_vat`, `eu_vat`, `gb_vat`, `ge_vat`, `gn_nif`, `hk_br`, `hr_oib`, `hu_tin`, `id_npwp`, `il_vat`, `in_gst`, `is_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `ke_pin`, `kg_tin`, `kh_tin`, `kr_brn`, `kz_bin`, `la_tin`, `li_uid`, `li_vat`, `ma_vat`, `md_vat`, `me_pib`, `mk_vat`, `mr_nif`, `mx_rfc`, `my_frp`, `my_itn`, `my_sst`, `ng_tin`, `no_vat`, `no_voec`, `np_pan`, `nz_gst`, `om_vat`, `pe_ruc`, `ph_tin`, `ro_tin`, `rs_pib`, `ru_inn`, `ru_kpp`, `sa_vat`, `sg_gst`, `sg_uen`, `si_tin`, `sn_ninea`, `sr_fin`, `sv_nit`, `th_vat`, `tj_tin`, `tr_tin`, `tw_vat`, `tz_vat`, `ua_vat`, `ug_tin`, `us_ein`, `uy_ruc`, `uz_tin`, `uz_vat`, `ve_rif`, `vn_tin`, `za_vat`, `zm_tin`, or `zw_tin`
      attr_accessor :type
      # Value of the tax ID.
      attr_accessor :value

      def initialize(type: nil, value: nil)
        @type = type
        @value = value
      end
    end
    # The customer's address.
    attr_accessor :address
    # An integer amount in cents (or local equivalent) that represents the customer's current balance, which affect the customer's future invoices. A negative amount represents a credit that decreases the amount due on an invoice; a positive amount increases the amount due on an invoice.
    attr_accessor :balance
    # The customer's business name. This may be up to *150 characters*.
    attr_accessor :business_name
    # Balance information and default balance settings for this customer.
    attr_accessor :cash_balance
    # An arbitrary string that you can attach to a customer object. It is displayed alongside the customer in the dashboard.
    attr_accessor :description
    # Customer's email address. It's displayed alongside the customer in your dashboard and can be useful for searching and tracking. This may be up to *512 characters*.
    attr_accessor :email
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The customer's full name. This may be up to *150 characters*.
    attr_accessor :individual_name
    # The prefix for the customer used to generate unique invoice numbers. Must be 3–12 uppercase letters or numbers.
    attr_accessor :invoice_prefix
    # Default invoice settings for this customer.
    attr_accessor :invoice_settings
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The customer's full name or business name.
    attr_accessor :name
    # The sequence to be used on the customer's next invoice. Defaults to 1.
    attr_accessor :next_invoice_sequence
    # Attribute for param field payment_method
    attr_accessor :payment_method
    # The customer's phone number.
    attr_accessor :phone
    # Customer's preferred languages, ordered by preference.
    attr_accessor :preferred_locales
    # The customer's shipping information. Appears on invoices emailed to this customer.
    attr_accessor :shipping
    # Attribute for param field source
    attr_accessor :source
    # Tax details about the customer.
    attr_accessor :tax
    # The customer's tax exemption. One of `none`, `exempt`, or `reverse`.
    attr_accessor :tax_exempt
    # The customer's tax IDs.
    attr_accessor :tax_id_data
    # ID of the test clock to attach to the customer.
    attr_accessor :test_clock
    # Attribute for param field validate
    attr_accessor :validate

    def initialize(
      address: nil,
      balance: nil,
      business_name: nil,
      cash_balance: nil,
      description: nil,
      email: nil,
      expand: nil,
      individual_name: nil,
      invoice_prefix: nil,
      invoice_settings: nil,
      metadata: nil,
      name: nil,
      next_invoice_sequence: nil,
      payment_method: nil,
      phone: nil,
      preferred_locales: nil,
      shipping: nil,
      source: nil,
      tax: nil,
      tax_exempt: nil,
      tax_id_data: nil,
      test_clock: nil,
      validate: nil
    )
      @address = address
      @balance = balance
      @business_name = business_name
      @cash_balance = cash_balance
      @description = description
      @email = email
      @expand = expand
      @individual_name = individual_name
      @invoice_prefix = invoice_prefix
      @invoice_settings = invoice_settings
      @metadata = metadata
      @name = name
      @next_invoice_sequence = next_invoice_sequence
      @payment_method = payment_method
      @phone = phone
      @preferred_locales = preferred_locales
      @shipping = shipping
      @source = source
      @tax = tax
      @tax_exempt = tax_exempt
      @tax_id_data = tax_id_data
      @test_clock = test_clock
      @validate = validate
    end
  end
end
