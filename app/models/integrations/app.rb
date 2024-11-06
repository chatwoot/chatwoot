class Integrations::App
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def id
    params[:id]
  end

  def name
    I18n.t("integration_apps.#{params[:i18n_key]}.name")
  end

  def description
    I18n.t("integration_apps.#{params[:i18n_key]}.description")
  end

  def logo
    params[:logo]
  end

  def fields
    params[:fields]
  end

  def action
    case params[:id]
    when 'slack'
      "#{params[:action]}&client_id=#{ENV.fetch('SLACK_CLIENT_ID', nil)}&redirect_uri=#{self.class.slack_integration_url}"
    else
      params[:action]
    end
  end

  def active?(account)
    case params[:id]
    when 'slack'
      ENV['SLACK_CLIENT_SECRET'].present?
    when 'linear'
      account.feature_enabled?('linear_integration')
    when 'captain'
      account.feature_enabled?('captain_integration') && ENV['CAPTAIN_API_URL'].present?
    else
      true
    end
  end

  def enabled?(account)
    case params[:id]
    when 'webhook'
      account.webhooks.exists?
    when 'dashboard_apps'
      account.dashboard_apps.exists?
    else
      account.hooks.exists?(app_id: id)
    end
  end

  def hooks
    Current.account.hooks.where(app_id: id)
  end

  def self.slack_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/settings/integrations/slack"
  end

  class << self
    def apps
      Hashie::Mash.new(APPS_CONFIG)
    end

    def all
      apps.values.each_with_object([]) do |app, result|
        integration_app = new(app)

        # adding internal apps to "onehash_apps"
        handle_onehash_apps(app) if integration_app.id == 'onehash_apps'

        result << integration_app
      end
    end

    def handle_onehash_apps(app)
      enabled_map = {
        onehash_cal: Current.user.custom_attributes&.key?('cal_events') || false
      }
      app.internal_apps.each do |_key, internal_app|
        enabled = enabled_map[internal_app.id.to_sym] || false
        dynamic_object = {
          enabled: enabled,
          name: I18n.t("integration_apps.#{internal_app.i18n_key}.name"),
          description: I18n.t("integration_apps.#{internal_app.i18n_key}.description")
        }

        internal_app.merge!(dynamic_object)
      end
    end

    def find(params)
      all.detect { |app| app.id == params[:id] }
    end
  end
end
