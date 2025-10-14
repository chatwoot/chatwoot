class Integrations::App
  include Linear::IntegrationHelper
  include Github::IntegrationHelper
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
    case params[:id]
    when 'slack'
      GlobalConfigService.load('SLACK_CLIENT_SECRET', nil).present?
    when 'linear'
      GlobalConfigService.load('LINEAR_CLIENT_ID', nil).present?
    when 'github'
      github_enabled?
    when 'shopify'
      shopify_enabled?(account)
    when 'leadsquared'
      account.feature_enabled?('crm_integration')
    when 'notion'
      notion_enabled?(account)
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
      'prompt=consent',
      'actor=app'
    ].join('&')
  end

  def build_github_action
    GlobalConfigService.load('GITHUB_CLIENT_ID', nil)

    # For GitHub Apps, redirect to installation page
    # The standard /installations/new URL should show org/user selection if the app is properly configured
    # Include state parameter with signed account ID for account context
    github_app_name = GlobalConfigService.load('GITHUB_APP_NAME', 'chatwoot-qa')
    state = Current.account.to_signed_global_id(expires_in: 1.hour)
    "https://github.com/apps/#{github_app_name}/installations/new?state=#{state}"
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

  private

  def github_enabled?
    GlobalConfigService.load('GITHUB_CLIENT_ID', nil).present? && GlobalConfigService.load('GITHUB_CLIENT_SECRET', nil).present?
  end

  def shopify_enabled?(account)
    account.feature_enabled?('shopify_integration') && GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil).present?
  end

  def notion_enabled?(account)
    account.feature_enabled?('notion_integration') && GlobalConfigService.load('NOTION_CLIENT_ID', nil).present?
  end
end
