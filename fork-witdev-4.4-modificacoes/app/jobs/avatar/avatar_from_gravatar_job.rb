class Avatar::AvatarFromGravatarJob < ApplicationJob
  queue_as :low

  def perform(avatarable, email)
    return if GlobalConfigService.load('DISABLE_GRAVATAR', '').present?
    return if email.blank?
    return if avatarable.avatar_url.present?

    hash = Digest::MD5.hexdigest(email)
    gravatar_url = "https://www.gravatar.com/avatar/#{hash}?d=404"
    Avatar::AvatarFromUrlJob.perform_later(avatarable, gravatar_url)
  end
end
