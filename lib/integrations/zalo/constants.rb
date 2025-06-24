class Integrations::Zalo::Constants
  def self.app_id
    @app_id ||= ENV.fetch('ZALO_APP_ID', nil)
  end

  def self.app_id!
    app_id || raise('ZALO_APP_ID is missing')
  end

  def self.app_secret
    @app_secret ||= ENV.fetch('ZALO_APP_SECRET', nil)
  end

  def self.app_secret!
    app_secret || raise('ZALO_APP_SECRET is missing')
  end

  def self.base_url
    'https://openapi.zalo.me'.freeze
  end
end
