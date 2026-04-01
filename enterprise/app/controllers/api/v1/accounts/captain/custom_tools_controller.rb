class Api::V1::Accounts::Captain::CustomToolsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }
  before_action :set_custom_tool, only: [:show, :update, :destroy]

  def index
    @custom_tools = account_custom_tools
  end

  def show; end

  def create
    @custom_tool = account_custom_tools.create!(custom_tool_params)
  rescue Captain::CustomTool::LimitExceededError => e
    render_could_not_create_error(e.message)
  end

  def update
    @custom_tool.update!(custom_tool_params)
  end

  def destroy
    @custom_tool.destroy
    head :no_content
  end

  def test
    tool = account_custom_tools.new(custom_tool_params)
    result = execute_test_request(tool)
    render json: { status: result.code.to_i, body: result.body.to_s.truncate(500) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def ensure_custom_tools_enabled
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  def set_custom_tool
    @custom_tool = account_custom_tools.find(params[:id])
  end

  def account_custom_tools
    @account_custom_tools ||= Current.account.captain_custom_tools
  end

  def execute_test_request(tool)
    uri = URI.parse(tool.endpoint_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 10
    http.open_timeout = 5

    request = tool.http_method == 'POST' ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
    tool.build_auth_headers.each { |key, value| request[key] = value }
    credentials = tool.build_basic_auth_credentials
    request.basic_auth(*credentials) if credentials

    http.request(request)
  end

  def custom_tool_params
    params.require(:custom_tool).permit(
      :title,
      :description,
      :endpoint_url,
      :http_method,
      :request_template,
      :response_template,
      :auth_type,
      :enabled,
      auth_config: {},
      param_schema: [:name, :type, :description, :required]
    )
  end
end
