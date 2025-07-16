require 'resend'

Resend.api_key = ENV.fetch('RESEND_API_KEY', nil)
