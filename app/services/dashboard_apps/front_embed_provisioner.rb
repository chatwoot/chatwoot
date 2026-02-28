require 'uri'

module DashboardApps
  class FrontEmbedProvisioner
    FRONT_ENABLED_KEY = 'FRONT_DASHBOARD_APP_ENABLED'.freeze
    FRONT_TITLE_KEY = 'FRONT_DASHBOARD_APP_TITLE'.freeze
    FRONT_URL_KEY = 'FRONT_DASHBOARD_APP_URL'.freeze
    EXTERNAL_NAME_KEY = 'EXTERNAL_APP_NAME'.freeze
    EXTERNAL_URL_KEY = 'EXTERNAL_APP_URL'.freeze
    DEFAULT_TITLE = 'Запись к врачу'.freeze
    DEFAULT_URL = 'http://127.0.0.1:3001/calendar'.freeze

    def self.sync_global_config!(logger: Rails.logger)
      app_url = resolve_app_url(logger: logger)
      app_title = resolve_app_title
      enabled_value = ENV.fetch(FRONT_ENABLED_KEY, 'true')

      upsert_config(FRONT_ENABLED_KEY, enabled_value)
      upsert_config(FRONT_TITLE_KEY, app_title)
      upsert_config(FRONT_URL_KEY, app_url)

      # Keep legacy External App page aligned with Dashboard Apps iframe target.
      upsert_config(EXTERNAL_NAME_KEY, app_title)
      upsert_config(EXTERNAL_URL_KEY, app_url)

      GlobalConfig.clear_cache
      logger.info("[front-dashboard-app] synced global config url=#{app_url} title=#{app_title.inspect}")
      { app_url: app_url, app_title: app_title, enabled: enabled_value }
    end

    def self.backfill!(account_id: nil, logger: Rails.logger)
      sync_global_config!(logger: logger)
      scope = account_id.present? ? Account.where(id: account_id) : Account.all
      scope.find_each do |account|
        result = new(account: account, logger: logger).perform
        logger.info("[front-dashboard-app] account=#{account.id} result=#{result}")
      rescue StandardError => e
        logger.error("[front-dashboard-app] account=#{account.id} failed: #{e.class} #{e.message}")
      end
    end

    def initialize(account:, logger: Rails.logger)
      @account = account
      @logger = logger
    end

    def perform
      return :skipped_disabled unless enabled?
      return :skipped_invalid_url unless valid_url?

      user = app_owner
      return :skipped_no_user unless user

      app = existing_app
      attrs = {
        title: app_title,
        content: [{ 'type' => 'frame', 'url' => app_url }],
        user_id: user.id
      }

      if app
        return :unchanged if unchanged?(app, attrs)

        app.update!(attrs)
        return :updated
      end

      @account.dashboard_apps.create!(attrs)
      :created
    end

    private

    def self.resolve_app_url(logger: Rails.logger)
      candidate = ENV.fetch(FRONT_URL_KEY, '').presence ||
                  ENV.fetch(EXTERNAL_URL_KEY, '').presence ||
                  DEFAULT_URL

      return candidate if valid_http_url?(candidate)

      logger.warn("[front-dashboard-app] invalid #{FRONT_URL_KEY}/#{EXTERNAL_URL_KEY}: #{candidate.inspect}, fallback to #{DEFAULT_URL}")
      DEFAULT_URL
    end

    def self.resolve_app_title
      ENV.fetch(FRONT_TITLE_KEY, '').presence ||
        ENV.fetch(EXTERNAL_NAME_KEY, '').presence ||
        DEFAULT_TITLE
    end

    def self.upsert_config(name, value)
      config = InstallationConfig.find_or_initialize_by(name: name)
      return if config.persisted? && config.value == value

      config.value = value
      config.locked = false if config.new_record?
      config.save!
    end

    def self.valid_http_url?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    def unchanged?(app, attrs)
      app.title == attrs[:title] &&
        app.user_id == attrs[:user_id] &&
        normalize_content(app.content) == attrs[:content]
    end

    def normalize_content(value)
      return [] unless value.is_a?(Array)

      value.map do |item|
        next unless item.is_a?(Hash)

        {
          'type' => item['type'] || item[:type],
          'url' => item['url'] || item[:url]
        }
      end.compact
    end

    def existing_app
      apps = @account.dashboard_apps.to_a
      apps.find { |app| first_content_url(app.content) == app_url } ||
        apps.find { |app| app.title == app_title }
    end

    def first_content_url(content)
      first = normalize_content(content).first
      first && first['url']
    end

    def app_owner
      @account.administrators.first || @account.users.first
    end

    def enabled?
      @enabled ||= ActiveModel::Type::Boolean.new.cast(
        GlobalConfigService.load(FRONT_ENABLED_KEY, 'true')
      )
    end

    def app_title
      @app_title ||= GlobalConfigService.load(FRONT_TITLE_KEY, '').presence ||
                     GlobalConfigService.load(EXTERNAL_NAME_KEY, '').presence ||
                     DEFAULT_TITLE
    end

    def app_url
      @app_url ||= GlobalConfigService.load(FRONT_URL_KEY, '').presence ||
                   GlobalConfigService.load(EXTERNAL_URL_KEY, '').presence ||
                   DEFAULT_URL
    end

    def valid_url?
      uri = URI.parse(app_url)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      @logger.warn("[front-dashboard-app] invalid url: #{app_url.inspect}")
      false
    end
  end
end
