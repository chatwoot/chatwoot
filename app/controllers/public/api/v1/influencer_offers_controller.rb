class Public::Api::V1::InfluencerOffersController < PublicController
  before_action :set_offer
  before_action :ensure_available, only: %i[show accept]

  def show
    render json: offer_json
  end

  def accept
    apply_selections
    voucher_code = Influencers::CreateVoucherService.new(offer: @offer).perform
    finalize_acceptance(voucher_code)
    render json: { voucher_code: voucher_code, voucher_value: @offer.voucher_value }
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

  def ensure_available
    render_unavailable if @offer.expired? || !@offer.pending?
  end

  def apply_selections
    @offer.selected_packages = params[:packages]&.to_unsafe_h || @offer.available_packages
    @offer.rights_level = params[:rights_level].presence || @offer.rights_level
    @offer.voucher_value = @offer.calculate_voucher_value(@offer.selected_packages, @offer.rights_level)
  end

  def finalize_acceptance(voucher_code)
    @offer.update!(status: :accepted, voucher_code: voucher_code, terms_accepted_at: Time.current)
    @offer.influencer_profile.transition_to!(:contacted) if @offer.influencer_profile.accepted?
  end

  def render_unavailable
    render json: { error: 'This offer has expired or is no longer available' }, status: :gone
  end

  def offer_json
    profile = @offer.influencer_profile
    {
      influencer: { username: profile.username, fullname: profile.fullname },
      brand: { name: 'Framky', logo_url: '/brand/framky-logo.svg' },
      available_packages: @offer.available_packages,
      default_rights: @offer.rights_level,
      custom_message: @offer.custom_message,
      expires_at: @offer.expires_at,
      calculator: { followers: profile.followers_count, fqs_score: profile.fqs_score }
    }
  end
end
