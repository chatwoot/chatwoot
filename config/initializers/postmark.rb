if Rails.env.production? || Rails.env.development?
  Postmark.api_token = ENV.fetch('POSTMARK_API_TOKEN')
  ActionMailer::Base.delivery_method = :postmark
  ActionMailer::Base.postmark_settings = {
    api_token: ENV.fetch('POSTMARK_API_TOKEN')
  }
end
