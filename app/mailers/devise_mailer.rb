class DeviseMailer < Devise::Mailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Flow <accounts@desarrollandoando.com>')
end
