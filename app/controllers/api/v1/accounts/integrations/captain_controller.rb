class Api::V1::Accounts::Integrations::CaptainController < Api::V1::Accounts::BaseController
  before_action :hook

  def proxy
    response = HTTParty.send(request_method, request_url, body: permitted_params[:body].to_json, headers: headers)
    render plain: response.body, status: response.code
  end

  private

  def headers
    {
      'X-User-Email' => hook.settings['account_email'],
      'X-User-Token' => hook.settings['access_token'],
      'Content-Type' => 'application/json',
      'Accept' => '*/*'
    }
  end

  def request_path
    if params[:route] == '/sessions/profile'
      'api/sessions/profile'
    else
      "api/accounts/#{hook.settings['account_id']}/#{params[:route]}"
    end
  end

  def request_url
    base_url = InstallationConfig.find_by(name: 'CAPTAIN_API_URL').value
    URI.join(base_url, request_path).to_s
  end

  def hook
    @hook ||= Current.account.hooks.find_by!(app_id: 'captain')
  end

  def request_method
    method = permitted_params[:method].downcase
    raise 'Invalid or missing HTTP method' unless %w[get post put patch delete options head].include?(method)

    method
  end

  def permitted_params
    params.permit(:method, :route, body: {})
  end
end
