class Integrations::App
  include Linear::IntegrationHelper
  include Github::IntegrationHelper
  attr_accessor :params

  INTEGRATION_CONFIGS = {
    'slack' => { config_key: 'SLACK_CLIENT_SECRET' },
    'linear' => { config_key: 'LINEAR_CLIENT_ID' },
    'shopify' => { feature_flag: 'shopify_integration', config_key: 'SHOPIFY_CLIENT_ID' },
    'leadsquared' => { feature_flag: 'crm_integration' },
    'github' => { feature_flag: 'github_integration', config_key: 'GITHUB_CLIENT_ID' }
  }.freeze

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

  # There is no way to get the account_id from the linear/github callback
  # so we are using the generate token method to generate a token and encode it in the state parameter
  def encode_state
    case params[:id]
    when 'linear'
      generate_linear_token(Current.account.id)
    when 'github'
      generate_github_token(Current.account.id)
    end
  end

  def action
    case params[:id]
    when 'slack'
      client_id = GlobalConfigService.load('SLACK_CLIENT_ID', nil)
      "#{params[:action]}&client_id=#{client_id}&redirect_uri=#{self.class.slack_integration_url}"
    when 'linear'
      build_linear_action
    when 'github'
      build_github_action
    else
      params[:action]
    end
  end

  def active?(account)
    config = INTEGRATION_CONFIGS[params[:id]]
    return true unless config

    feature_enabled = config[:feature_flag].nil? || account.feature_enabled?(config[:feature_flag])
    config_present = config[:config_key].nil? || GlobalConfigService.load(config[:config_key], nil).present?

    feature_enabled && config_present
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

  def build_github_action
    app_id = GlobalConfigService.load('GITHUB_CLIENT_ID', nil)
    [
      "#{params[:action]}?response_type=code",
      "client_id=#{app_id}",
      "redirect_uri=#{self.class.github_integration_url}",
      "state=#{encode_state}",
      'scope=repo'
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

  def self.github_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/github/callback"
  end

  class << self
    def apps
      Hashie::Mash.new(APPS_CONFIG)
    end

    def all
      apps.values.each_with_object([]) do |app, result|
        result << new(app)
      end
    end

    def find(params)
      all.detect { |app| app.id == params[:id] }
    end
  end
end
