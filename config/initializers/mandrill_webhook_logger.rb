# config/initializers/mandrill_webhook_logging.rb
class MandrillWebhookLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.include?('/rails/action_mailbox/mandrill/inbound_emails')
      Rails.logger.info "Mandrill Ingress Request: #{req.request_method} #{req.url}"
      Rails.logger.info "Headers: #{env.select { |k, _v| k.start_with?('HTTP_') || k == 'CONTENT_TYPE' }}"
      Rails.logger.info "Body: #{req.body.read}"
      req.body.rewind
    end
    @app.call(env)
  rescue ActionController::BadRequest => e
    Rails.logger.error "400 Bad Request in Mandrill Ingress: #{e.class} - #{e.message}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}" if e.backtrace
    raise
  rescue StandardError => e
    Rails.logger.error "StandardError in Mandrill Ingress: #{e.class} - #{e.message}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}" if e.backtrace
    raise
  end
end

Rails.application.config.middleware.insert_before 0, MandrillWebhookLogger
