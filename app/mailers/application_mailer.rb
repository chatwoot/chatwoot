class ApplicationMailer < ActionMailer::Base
  default from: 'accounts@chatwoot.com'
  layout 'mailer'

  # helpers
  helper :frontend_urls
end
