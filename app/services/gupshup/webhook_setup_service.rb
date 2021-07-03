
class Gupshup::WebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!]

  def perform
    Rails.logger.info "Gupshup webhook setup for: #{channel.phone_number}"
  end
end
