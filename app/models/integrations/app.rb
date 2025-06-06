class Integrations::App
  include Linear::IntegrationHelper
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

  def short_description
    I18n.t("integration_apps.#{params[:i18n_key]}.short_description")
  end

  def logo
    params[:logo]
  end

  def fields
    params[:fields]
  end

  # There is no way to get the account_id from the linear callback
  # so we are using the generate_linear_token method to generate a token and encode it in the state parameter
  def encode_state
    generate_linear_token(Current.account.id)
  end

  def action
    case params[:id]
    when 'slack'
      "#{params[:action]}&client_id=#{ENV.fetch('SLACK_CLIENT_ID', nil)}&redirect_uri=#{self.class.slack_integration_url}"
    when 'linear'
      build_linear_action
    else
      params[:action]
    end
  end

  def active?(account)
    case params[:id]
    when 'slack'
      ENV['SLACK_CLIENT_SECRET'].present?
    when 'linear'
      GlobalConfigService.load('LINEAR_CLIENT_ID', nil).present?
    when 'shopify'
      account.feature_enabled?('shopify_integration') && GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil).present?
    when 'leadsquared'
      account.feature_enabled?('crm_integration')
    else
      true
    end
  end

  def build_linear_action
    app_id = GlobalConfigService.load('LINEAR_CLIENT_ID', nil)
    [
      "#{params[:action]}?response_type=code",
      "client_id=#{app_id}",
      "redirect_uri=#{self.class.linear_integration_url}",
      "state=#{encode_state}",
      'scope=read,write',
      'prompt=consent'
    ].join('&')
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

  def self.linear_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/linear/callback"
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
        onehash_cal: Integrations::Hook.exists?(app_id: 'onehash_cal', account_user_id: Current.account_user.id)
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
