class Api::V1::Accounts::Integrations::CaptainController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :hook
  before_action :validate_method, only: :proxy

  def proxy
    base_url = InstallationConfig.find_by(name: 'CAPTAIN_API_URL').value
    url = "#{base_url}/accounts/#{hook.settings['account_id']}#{params[:route]}"

    # make the request to the Captain service
    # also add the access token and email to header use X-User-Email and X-User-Token
    response = HTTParty.send(params[:method].downcase, url, body: params[:body], headers: {
                               'X-User-Email' => hook.settings['account_email'],
                               'X-User-Token' => hook.settings['access_token']
                             })

    render json: response.body, status: response.code
  end

  private

  def hook
    @hook ||= Current.account.hooks.find_by!(app_id: 'captain')
  end

  def validate_method
    return if params[:method].present? && %w[get post put delete].include?(params[:method].downcase)

    render json: { error: 'Invalid or missing HTTP method' }, status: :unprocessable_entity
  end
end
