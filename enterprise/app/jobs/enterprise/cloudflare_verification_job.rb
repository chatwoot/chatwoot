class Enterprise::CloudflareVerificationJob < ApplicationJob
  queue_as :default

  def perform(portal_id)
    portal = Portal.find(portal_id)
    return unless portal && portal.custom_domain.present?

    result = check_hostname_status(portal)

    create_hostname(portal) if result[:errors].present?
  end

  private

  def create_hostname(portal)
    result = Cloudflare::CreateCustomHostnameService.new(portal: portal).perform
    return if result[:errors].blank?

    Rails.logger.error("[CLOUDFLARE] Custom hostname create failed for portal #{portal.id} (#{portal.custom_domain}): #{result[:errors]}")
  end

  def check_hostname_status(portal)
    Cloudflare::CheckCustomHostnameService.new(portal: portal).perform
  end
end
