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
    Cloudflare::CreateCustomHostnameService.new(portal: portal).perform
  end

  def check_hostname_status(portal)
    Cloudflare::CheckCustomHostnameService.new(portal: portal).perform
  end
end
