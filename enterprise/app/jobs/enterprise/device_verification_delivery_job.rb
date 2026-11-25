class Enterprise::DeviceVerificationDeliveryJob < ActionMailer::MailDeliveryJob
  # The job args carry the plaintext verification code; keep it out of logs.
  self.log_arguments = false
end
