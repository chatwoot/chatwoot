# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# Optional cross-origin embedding configuration.
#
# CW_ALLOWED_EMBED_ORIGINS: comma-separated list of origins. When set,
#   CORS is restricted to these origins (replacing the default '*') and a
#   `Content-Security-Policy: frame-ancestors 'self' <origins>` header is
#   emitted on every response.
# CW_ENABLE_CROSS_ORIGIN_ISOLATION: when true, adds
#   `Cross-Origin-Embedder-Policy: credentialless` and
#   `Cross-Origin-Resource-Policy: cross-origin` to every response.
#
# Both default to off; leaving them unset preserves existing behaviour.
class CrossOriginEmbedHeaders
  def self.allowed_origins
    ENV.fetch('CW_ALLOWED_EMBED_ORIGINS', '').split(',').map(&:strip).reject(&:empty?)
  end

  def self.cross_origin_isolation?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_ENABLE_CROSS_ORIGIN_ISOLATION', false))
  end

  def initialize(app)
    @app = app
    @allowed_origins = self.class.allowed_origins
    @cross_origin_isolation = self.class.cross_origin_isolation?
  end

  def call(env)
    status, headers, response = @app.call(env)

    if @cross_origin_isolation
      headers['cross-origin-embedder-policy'] = 'credentialless'
      headers['cross-origin-resource-policy'] = 'cross-origin'
    end

    headers['content-security-policy'] = "frame-ancestors 'self' #{@allowed_origins.join(' ')};" if @allowed_origins.any?

    [status, headers, response]
  end
end

# font cors issue with CDN
# Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*(CrossOriginEmbedHeaders.allowed_origins.presence || ['*']))
    resource '/packs/*', headers: :any, methods: [:get, :options]
    resource '/audio/*', headers: :any, methods: [:get, :options]
    # Make the public endpoints accessible to the frontend
    resource '/public/api/*', headers: :any, methods: :any

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
      resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
    end

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_API_CORS', false))
      resource '/api/*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
    end
  end
end

if CrossOriginEmbedHeaders.allowed_origins.any? || CrossOriginEmbedHeaders.cross_origin_isolation?
  Rails.application.config.middleware.insert_before Rack::Cors, CrossOriginEmbedHeaders
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
