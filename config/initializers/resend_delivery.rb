# Register Resend API as a custom ActionMailer delivery method
require Rails.root.join('lib/resend_delivery')

ActionMailer::Base.add_delivery_method(:resend_api, ResendDelivery)