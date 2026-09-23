class Enterprise::UnknownSignInNotificationJob < ApplicationJob
  queue_as :low

  def perform(recipient_email, device)
    return unless UnknownSignInNotification.enabled?

    device = device.to_h.symbolize_keys
    return if recipient_email.blank?

    geo = IpLookupService.new.perform(device[:ip]) if device[:ip].present?
    meta = device.merge(email: recipient_email, city: geo&.city, country: geo&.country)
    Enterprise::UnknownSignInMailer.unknown_sign_in(meta).deliver_later
  end
end
