class Github::CallbacksController < ApplicationController
  include Github::IntegrationHelper
  before_action :authenticate_user!
  before_action :set_account

  def show
    if params[:error].present?
      redirect_to app_account_integrations_path(account_id: @account.id), alert: params[:error_description]
      return
    end

    if params[:code].present?
      response = exchange_code_for_token(params[:code])

      if response[:access_token].present?
        hook = @account.hooks.find_or_initialize_by(app_id: 'github')
        hook.access_token = response[:access_token]
        hook.status = 'enabled'

        if hook.save
          redirect_to app_account_integrations_path(account_id: @account.id), notice: 'GitHub integration connected successfully!'
        else
          redirect_to app_account_integrations_path(account_id: @account.id), alert: 'Failed to save GitHub integration'
        end
      else
        redirect_to app_account_integrations_path(account_id: @account.id), alert: 'Failed to get access token from GitHub'
      end
    else
      redirect_to app_account_integrations_path(account_id: @account.id), alert: 'GitHub authorization failed'
    end
  end

  private

  def set_account
    @account = Current.user.accounts.find(params[:account_id]) if params[:account_id].present?
    @account ||= Current.user.accounts.first

    return if @account

    redirect_to root_path, alert: 'Account not found'
  end

  def exchange_code_for_token(code)
    client_id = GlobalConfigService.load('GITHUB_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('GITHUB_CLIENT_SECRET', nil)

    return {} unless client_id && client_secret

    response = HTTParty.post('https://github.com/login/oauth/access_token', {
                               body: {
                                 client_id: client_id,
                                 client_secret: client_secret,
                                 code: code
                               },
                               headers: {
                                 'Accept' => 'application/json'
                               }
                             })

    if response.success?
      JSON.parse(response.body).with_indifferent_access
    else
      {}
    end
  rescue StandardError => e
    Rails.logger.error "GitHub OAuth error: #{e.message}"
    {}
  end
end