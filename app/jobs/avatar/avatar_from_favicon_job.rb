class Avatar::AvatarFromFaviconJob < ApplicationJob
  queue_as :purgable
  def perform(company)
    return if company.domain.blank?
    return if company.avatar_url.present?

    favicon_url = "https://www.google.com/s2/favicons?domain=#{company.domain}&sz=256"
    Avatar::AvatarFromUrlJob.perform_later(company, favicon_url)
  end
end
