module Whatsapp::WebhookUrlBuilder
  class << self
    def build(phone_number, base_url: nil)
      resolved_base_url = resolve_base_url(base_url)
      return nil if resolved_base_url.blank?

      "#{resolved_base_url.chomp('/')}/webhooks/whatsapp/#{phone_number}"
    end

    private

    def resolve_base_url(base_url)
      base_url.presence ||
        Current.webhook_base_url.presence ||
        ENV.fetch('WEBHOOK_BASE_URL', nil).presence ||
        ENV.fetch('FRONTEND_URL', nil)
    end
  end
end
