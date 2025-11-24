# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# font cors issue with CDN
# Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Ler domínios da variável de ambiente CORS_ALLOWED_ORIGINS
    cors_origins = ENV.fetch('CORS_ALLOWED_ORIGINS', '*').split(',').map(&:strip)
    origins *cors_origins

    # Liberar TODAS as rotas para os domínios permitidos
    # Credentials só é habilitado quando não for wildcard (por segurança)
    is_wildcard = cors_origins.include?('*')

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: %w[access-token client uid expiry token-type],
      credentials: !is_wildcard
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
