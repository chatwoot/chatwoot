# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxIdCreateParams < ::Stripe::RequestParams
    class Owner < ::Stripe::RequestParams
      # Account the tax ID belongs to. Required when `type=account`
      attr_accessor :account
      # Customer the tax ID belongs to. Required when `type=customer`
      attr_accessor :customer
      # Type of owner referenced.
      attr_accessor :type

      def initialize(account: nil, customer: nil, type: nil)
        @account = account
        @customer = customer
        @type = type
      end
    end
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The account or customer the tax ID belongs to. Defaults to `owner[type]=self`.
    attr_accessor :owner
    # Type of the tax ID, one of `ad_nrt`, `ae_trn`, `al_tin`, `am_tin`, `ao_tin`, `ar_cuit`, `au_abn`, `au_arn`, `aw_tin`, `az_tin`, `ba_tin`, `bb_tin`, `bd_bin`, `bf_ifu`, `bg_uic`, `bh_vat`, `bj_ifu`, `bo_tin`, `br_cnpj`, `br_cpf`, `bs_tin`, `by_tin`, `ca_bn`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `ca_qst`, `cd_nif`, `ch_uid`, `ch_vat`, `cl_tin`, `cm_niu`, `cn_tin`, `co_nit`, `cr_tin`, `cv_nif`, `de_stn`, `do_rcn`, `ec_ruc`, `eg_tin`, `es_cif`, `et_tin`, `eu_oss_vat`, `eu_vat`, `gb_vat`, `ge_vat`, `gn_nif`, `hk_br`, `hr_oib`, `hu_tin`, `id_npwp`, `il_vat`, `in_gst`, `is_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `ke_pin`, `kg_tin`, `kh_tin`, `kr_brn`, `kz_bin`, `la_tin`, `li_uid`, `li_vat`, `ma_vat`, `md_vat`, `me_pib`, `mk_vat`, `mr_nif`, `mx_rfc`, `my_frp`, `my_itn`, `my_sst`, `ng_tin`, `no_vat`, `no_voec`, `np_pan`, `nz_gst`, `om_vat`, `pe_ruc`, `ph_tin`, `ro_tin`, `rs_pib`, `ru_inn`, `ru_kpp`, `sa_vat`, `sg_gst`, `sg_uen`, `si_tin`, `sn_ninea`, `sr_fin`, `sv_nit`, `th_vat`, `tj_tin`, `tr_tin`, `tw_vat`, `tz_vat`, `ua_vat`, `ug_tin`, `us_ein`, `uy_ruc`, `uz_tin`, `uz_vat`, `ve_rif`, `vn_tin`, `za_vat`, `zm_tin`, or `zw_tin`
    attr_accessor :type
    # Value of the tax ID.
    attr_accessor :value

    def initialize(expand: nil, owner: nil, type: nil, value: nil)
      @expand = expand
      @owner = owner
      @type = type
      @value = value
    end
  end
end
