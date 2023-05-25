# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# rubocop:disable Rails/ApplicationRecord
class WebWidget < ActiveRecord::Base
  self.table_name = 'channel_web_widgets'
end
# rubocop:enable Rails/ApplicationRecord

unless ENV.fetch('FRONTEND_URL', nil).nil?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins ENV.fetch('FRONTEND_URL', '')
      resource '/packs/*', headers: :any, methods: [:get, :options]
      resource '/audio/*', headers: :any, methods: [:get, :options]
      # Make the public endpoints accessible to the frontend
      resource '/public/api/*', headers: :any, methods: :any

      if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
        resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
      end
    end
  end
end

if ENV.fetch('CORS_WIDGET_CONFIG', true)
  WebWidget.all.each do |widget|
    # font cors issue with CDN
    # Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
    Rails.application.config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins widget.website_url
        resource '/packs/*', headers: :any, methods: [:get, :options]
        resource '/audio/*', headers: :any, methods: [:get, :options]
        # Make the public endpoints accessible to the frontend
        resource '/public/api/*', headers: :any, methods: :any

        if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
          resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
        end
      end
    end
  end
else
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '/packs/*', headers: :any, methods: [:get, :options]
      resource '/audio/*', headers: :any, methods: [:get, :options]
      # Make the public endpoints accessible to the frontend
      resource '/public/api/*', headers: :any, methods: :any

      if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
        resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
      end
    end
  end
end

################################################
######### Action Cable Related Config ##########
################################################

# Mount Action Cable outside main process or domain
# Rails.application.config.action_cable.mount_path = nil
# Rails.application.config.action_cable.url = 'wss://example.com/cable'
# Rails.application.config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

# To Enable connecting to the API channel public APIs
# ref : https://medium.com/@emikaijuin/connecting-to-action-cable-without-rails-d39a8aaa52d5
Rails.application.config.action_cable.disable_request_forgery_protection = true
