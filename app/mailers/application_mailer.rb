class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  # helpers
  helper :frontend_urls
end
