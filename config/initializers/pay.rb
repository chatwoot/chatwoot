Pay.setup do |config|
  config.business_name = 'AlooChat'
  config.business_address = 'Kuwait'
  config.application_name = 'AlooChat'
  config.support_email = ENV.fetch('MAILER_SENDER_EMAIL', 'support@aloochat.com')

  config.default_product_name = 'AlooChat'
  config.default_plan_name = 'basic'

  config.automount_routes = true
  config.routes_path = '/pay'

  config.enabled_processors = [:stripe]
end
