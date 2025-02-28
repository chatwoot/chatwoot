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
      account.feature_enabled?('linear_integration')
    else
      true
    end
  end

  def build_linear_action
    [
      "#{params[:action]}?response_type=code",
      "client_id=#{ENV.fetch('LINEAR_CLIENT_ID', nil)}",
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
        result << new(app)
      end
    end

    def find(params)
      all.detect { |app| app.id == params[:id] }
    end
  end
end
