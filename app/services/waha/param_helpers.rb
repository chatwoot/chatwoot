module Waha::ParamHelpers
  def message_params?
    params.dig(:message, :text).present? ||
      params[:body].present? ||
      params[:caption].present?
  end

  def message_content
    params.dig(:message, :text) || params[:body] || params[:caption]
  end

  def phone_number
    return nil if params[:from].blank?

    params[:from]&.split('@')&.first
  end

  def formatted_phone_number
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def sender_full_name
    params[:pushname] || phone_number
  end

  def sender_id
    params[:sessionID]
  end

  def message_id
    params.dig(:message, :id) || sender_id
  end
end
