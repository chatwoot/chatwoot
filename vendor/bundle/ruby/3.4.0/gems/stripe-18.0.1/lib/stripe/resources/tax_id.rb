# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # You can add one or multiple tax IDs to a [customer](https://stripe.com/docs/api/customers) or account.
  # Customer and account tax IDs get displayed on related invoices and credit notes.
  #
  # Related guides: [Customer tax identification numbers](https://stripe.com/docs/billing/taxes/tax-ids), [Account tax IDs](https://stripe.com/docs/invoicing/connect#account-tax-ids)
  class TaxId < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List

    OBJECT_NAME = "tax_id"
    def self.object_name
      "tax_id"
    end

    class Owner < ::Stripe::StripeObject
      # The account being referenced when `type` is `account`.
      attr_reader :account
      # The Connect Application being referenced when `type` is `application`.
      attr_reader :application
      # The customer being referenced when `type` is `customer`.
      attr_reader :customer
      # Type of owner referenced.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Verification < ::Stripe::StripeObject
      # Verification status, one of `pending`, `verified`, `unverified`, or `unavailable`.
      attr_reader :status
      # Verified address.
      attr_reader :verified_address
      # Verified name.
      attr_reader :verified_name

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Two-letter ISO code representing the country of the tax ID.
    attr_reader :country
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # ID of the customer.
    attr_reader :customer
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account or customer the tax ID belongs to.
    attr_reader :owner
    # Type of the tax ID, one of `ad_nrt`, `ae_trn`, `al_tin`, `am_tin`, `ao_tin`, `ar_cuit`, `au_abn`, `au_arn`, `aw_tin`, `az_tin`, `ba_tin`, `bb_tin`, `bd_bin`, `bf_ifu`, `bg_uic`, `bh_vat`, `bj_ifu`, `bo_tin`, `br_cnpj`, `br_cpf`, `bs_tin`, `by_tin`, `ca_bn`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `ca_qst`, `cd_nif`, `ch_uid`, `ch_vat`, `cl_tin`, `cm_niu`, `cn_tin`, `co_nit`, `cr_tin`, `cv_nif`, `de_stn`, `do_rcn`, `ec_ruc`, `eg_tin`, `es_cif`, `et_tin`, `eu_oss_vat`, `eu_vat`, `gb_vat`, `ge_vat`, `gn_nif`, `hk_br`, `hr_oib`, `hu_tin`, `id_npwp`, `il_vat`, `in_gst`, `is_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `ke_pin`, `kg_tin`, `kh_tin`, `kr_brn`, `kz_bin`, `la_tin`, `li_uid`, `li_vat`, `ma_vat`, `md_vat`, `me_pib`, `mk_vat`, `mr_nif`, `mx_rfc`, `my_frp`, `my_itn`, `my_sst`, `ng_tin`, `no_vat`, `no_voec`, `np_pan`, `nz_gst`, `om_vat`, `pe_ruc`, `ph_tin`, `ro_tin`, `rs_pib`, `ru_inn`, `ru_kpp`, `sa_vat`, `sg_gst`, `sg_uen`, `si_tin`, `sn_ninea`, `sr_fin`, `sv_nit`, `th_vat`, `tj_tin`, `tr_tin`, `tw_vat`, `tz_vat`, `ua_vat`, `ug_tin`, `us_ein`, `uy_ruc`, `uz_tin`, `uz_vat`, `ve_rif`, `vn_tin`, `za_vat`, `zm_tin`, or `zw_tin`. Note that some legacy tax IDs have type `unknown`
    attr_reader :type
    # Value of the tax ID.
    attr_reader :value
    # Tax ID verification information.
    attr_reader :verification
    # Always true for a deleted object
    attr_reader :deleted

    # Creates a new account or customer tax_id object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/tax_ids", params: params, opts: opts)
    end

    # Deletes an existing account or customer tax_id object.
    def self.delete(id, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/tax_ids/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts
      )
    end

    # Deletes an existing account or customer tax_id object.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/tax_ids/%<id>s", { id: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of tax IDs.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/tax_ids", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = { owner: Owner, verification: Verification }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
