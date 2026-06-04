# resend gem is optional – gracefully skip if not installed
begin
  require 'resend'
  Resend.api_key = ENV.fetch('RESEND_API_KEY', nil)
rescue LoadError
  Rails.logger.debug { '[resend] gem not installed – transactional email via Resend is disabled.' }
end
