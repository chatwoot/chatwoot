module Twilio::ReferralParamsHelper
  REFERRAL_PARAM_MAPPING = {
    source_id: :ReferralSourceId,
    source_type: :ReferralSourceType,
    source_url: :ReferralSourceUrl,
    headline: :ReferralHeadline,
    body: :ReferralBody,
    media_id: :ReferralMediaId,
    media_content_type: :ReferralMediaContentType,
    media_url: :ReferralMediaUrl,
    num_media: :ReferralNumMedia,
    ctwa_clid: :ReferralCtwaClid
  }.freeze

  def message_content_attributes
    referral_attributes.present? ? { referral: referral_attributes } : {}
  end

  def referral_attributes
    return {} unless twilio_channel.whatsapp?
    return {} if params[:ReferralSourceId].blank?

    REFERRAL_PARAM_MAPPING.each_with_object({}) do |(attribute, param_key), result|
      value = params[param_key]
      result[attribute] = value if value.present?
    end
  end
end
