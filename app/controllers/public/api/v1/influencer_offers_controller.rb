class Public::Api::V1::InfluencerOffersController < PublicController
  before_action :set_offer
  before_action :ensure_showable, only: :show
  before_action :ensure_available, only: :accept

  def show
    render json: offer_json
  end

  def accept
    apply_selections
    apply_consents
    result = Influencers::CreateVoucherService.new(offer: @offer).perform
    finalize_acceptance(result[:voucher_code], result[:referral_link])
    render json: { voucher_code: result[:voucher_code], voucher_value: @offer.voucher_value, referral_link: result[:referral_link] }
  rescue Influencers::CreateVoucherService::VoucherCreationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def calculate
    packages = params[:packages]&.to_unsafe_h || @offer.available_packages
    rights = params[:rights_level].presence || 'standard'
    value = @offer.calculate_voucher_value(packages, rights)
    render json: { value: value, currency: @offer.voucher_currency }
  end

  private

  def set_offer
    @offer = InfluencerOffer.find_by!(token: params[:token])
  end

  def ensure_showable
    render_unavailable unless @offer.pending? || @offer.accepted?
  end

  def ensure_available
    render_unavailable if @offer.expired? || !@offer.pending?
  end

  def apply_selections
    @offer.selected_packages = params[:packages]&.to_unsafe_h || @offer.available_packages
    @offer.rights_level = params[:rights_level].presence || @offer.rights_level
    @offer.voucher_value = @offer.calculate_voucher_value(@offer.selected_packages, @offer.rights_level)
  end

  def apply_consents
    @offer.consent_data_processing = ActiveModel::Type::Boolean.new.cast(params[:consent_data_processing])
    @offer.consent_terms = ActiveModel::Type::Boolean.new.cast(params[:consent_terms])
  end

  def finalize_acceptance(voucher_code, referral_link)
    version = params[:offer_page_version].presence || InfluencerOffer::CURRENT_OFFER_PAGE_VERSION
    @offer.update!(status: :accepted, voucher_code: voucher_code, referral_link: referral_link, terms_accepted_at: Time.current,
                   offer_page_version: version)
    @offer.influencer_profile.transition_to!(:confirmed) if @offer.influencer_profile.contacted?
  end

  def render_unavailable
    render json: { error: 'This offer has expired or is no longer available' }, status: :gone
  end

  def offer_json
    profile = @offer.influencer_profile
    json = {
      influencer: { username: profile.username, fullname: profile.fullname },
      brand: { name: 'Framky', logo_url: '/brand/framky-logo.svg' },
      available_packages: @offer.available_packages,
      default_rights: @offer.rights_level,
      custom_message: @offer.custom_message,
      expires_at: @offer.expires_at,
      calculator: { followers: profile.followers_count, fqs_score: profile.fqs_score },
      status: @offer.status
    }
    if @offer.accepted?
      json.merge!(
        voucher_code: @offer.voucher_code,
        voucher_value: @offer.voucher_value,
        voucher_currency: @offer.voucher_currency,
        referral_link: @offer.referral_link,
        selected_packages: @offer.selected_packages,
        rights_level: @offer.rights_level
      )
    end
    json
  end
end
