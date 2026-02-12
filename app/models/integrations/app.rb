class Integrations::App
  include Linear::IntegrationHelper
  include Calendly::IntegrationHelper
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

  # There is no way to get the account_id from the linear/calendly callback
  # so we are using JWT tokens to encode the account_id in the state parameter
  def encode_state(provider = :linear)
    case provider
    when :calendly
      generate_calendly_token(Current.account.id)
    else
      generate_linear_token(Current.account.id)
    end
  end

  def action
    case params[:id]
    when 'slack'
      client_id = GlobalConfigService.load('SLACK_CLIENT_ID', nil)
      "#{params[:action]}&client_id=#{client_id}&redirect_uri=#{self.class.slack_integration_url}"
    when 'linear'
      build_linear_action
    when 'calendly'
      build_calendly_action
    else
      params[:action]
    end
  end

  ACTIVE_CHECKS = {
    'slack' => ->(_account) { GlobalConfigService.load('SLACK_CLIENT_SECRET', nil).present? },
    'linear' => ->(account) { account.feature_enabled?('linear_integration') && GlobalConfigService.load('LINEAR_CLIENT_ID', nil).present? },
    'shopify' => ->(account) { account.feature_enabled?('shopify_integration') && GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil).present? },
    'leadsquared' => ->(account) { account.feature_enabled?('crm_integration') },
    'notion' => ->(account) { account.feature_enabled?('notion_integration') && GlobalConfigService.load('NOTION_CLIENT_ID', nil).present? },
    'calendly' => ->(_account) { GlobalConfigService.load('CALENDLY_CLIENT_ID', nil).present? }
  }.freeze

  def active?(account)
    check = ACTIVE_CHECKS[params[:id]]
    return true if check.nil?

    check.call(account)
  end

  def build_calendly_action
    app_id = GlobalConfigService.load('CALENDLY_CLIENT_ID', nil)
    [
      "#{params[:action]}?response_type=code",
      "client_id=#{app_id}",
      "redirect_uri=#{self.class.calendly_integration_url}",
      "state=#{encode_state(:calendly)}"
    ].join('&')
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

  def self.calendly_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/calendly/callback"
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
        result << new(app)
      end
    end

    def find(params)
      all.detect { |app| app.id == params[:id] }
    end
  end
end
