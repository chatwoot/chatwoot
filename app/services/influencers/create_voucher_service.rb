class Influencers::CreateVoucherService
  API_URL = ENV.fetch('FRAMKY_API_URL', 'https://api.framky.com')

  class VoucherCreationError < StandardError; end

  def initialize(offer:)
    @offer = offer
  end

  def perform
    response = HTTParty.post(
      "#{API_URL}/orders/coupons/",
      headers: auth_headers,
      body: coupon_payload.to_json
    )
    raise VoucherCreationError, "Voucher creation failed: #{response.code} — #{response.body}" unless response.success?

    {
      voucher_code: response.parsed_response['code'],
      referral_link: build_referral_link
    }
  end

  private

  def coupon_payload
    {
      code: generate_code,
      discount_amount: @offer.voucher_value.to_f,
      discount_amount_currency: @offer.voucher_currency,
      redeem_limit: 1,
      redeem_by: 90.days.from_now.strftime('%Y-%m-%d')
    }
  end

  def generate_code
    username = @offer.influencer_profile.username.upcase.gsub(/[^A-Z0-9]/, '')[0..8]
    suffix = SecureRandom.alphanumeric(4).upcase
    "INF-#{username}-#{suffix}"
  end

  def build_referral_link
    username = @offer.influencer_profile.username
    "https://framky.com/#{username}"
  end

  def auth_headers
    {
      'Authorization' => "Token #{ENV.fetch('FRAMKY_API_TOKEN')}",
      'Content-Type' => 'application/json'
    }
  end
end
