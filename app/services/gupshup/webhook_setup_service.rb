
class Gupshup::WebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!]

  def perform
    puts "hi"
    true
  end
end

