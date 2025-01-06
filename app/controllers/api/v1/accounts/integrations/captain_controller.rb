class Api::V1::Accounts::Integrations::CaptainController < Api::V1::Accounts::BaseController
  before_action :hook

  def proxy
    request_url = build_request_url(request_path)
    response = HTTParty.send(request_method, request_url, body: permitted_params[:body].to_json, headers: headers)
    render plain: response.body, status: response.code
  end

  def copilot
    request_url = build_request_url(build_request_path("/assistants/#{hook.settings['assistant_id']}/copilot"))
    params = {
      previous_messages: copilot_params[:previous_messages],
      conversation_history: conversation_history,
      message: copilot_params[:message]
    }
    response = HTTParty.send(:post, request_url, body: params.to_json, headers: headers)
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

  def build_request_path(route)
    "api/accounts/#{hook.settings['account_id']}#{route}"
  end

  def request_path
    request_route = with_leading_hash_on_route(params[:route])

    return 'api/sessions/profile' if request_route == '/sessions/profile'

    build_request_path(request_route)
  end

  def build_request_url(request_path)
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

  def with_leading_hash_on_route(request_route)
    return '' if request_route.blank?

    request_route.start_with?('/') ? request_route : "/#{request_route}"
  end

  def conversation_history
    conversation = Current.account.conversations.find_by!(display_id: copilot_params[:conversation_id])
    conversation.to_llm_text
  end

  def copilot_params
    params.permit(:previous_messages, :conversation_id, :message)
  end

  def permitted_params
    params.permit(:method, :route, body: {})
  end
end
