class Api::V1::Accounts::Captain::CustomToolsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }
  before_action :set_current_page, only: [:index]
  before_action :set_custom_tool, only: [:show, :update, :destroy]
  before_action :validate_headers_param, only: [:create, :update, :test]

  def index
    @custom_tools_count = assistant_custom_tools.count
    @custom_tools = assistant_custom_tools.order(id: :desc).page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @custom_tool = assistant_custom_tools.create!(custom_tool_params.merge(account: Current.account))
  rescue Captain::CustomTool::LimitExceededError => e
    render_could_not_create_error(e.message)
  end

  def update
    # Tools installed from a manifest are managed by their manifest; only the user-owned enabled flag can change
    if @custom_tool.source_metadata.present? && (custom_tool_params.keys - ['enabled']).any?
      return render_could_not_create_error(I18n.t('captain.custom_tool.installed_read_only'))
    end

    @custom_tool.update!(custom_tool_params)
  end

  def destroy
    @custom_tool.destroy
    head :no_content
  end

  def test
    tool = assistant_custom_tools.new(custom_tool_params.merge(account: Current.account))
    tool.validate
    # Only the request-shaping fields matter here, so a draft without a title can still be tested
    request_errors = %i[endpoint_url headers auth_config].flat_map { |attribute| tool.errors.full_messages_for(attribute) }
    return render json: { error: request_errors.to_sentence }, status: :unprocessable_content if request_errors.any?

    body = execute_test_request(tool)
    render json: { status: 200, body: body.to_s.truncate(500) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_current_page
    @current_page = params.fetch(:page, 1).to_i
  end

  def ensure_custom_tools_enabled
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  # permit(headers: {}) silently drops non-object values, so reject them before they are filtered out
  def validate_headers_param
    return unless params[:custom_tool]&.key?(:headers)
    return if params[:custom_tool][:headers].is_a?(ActionController::Parameters)

    render_could_not_create_error("#{Captain::CustomTool.human_attribute_name(:headers)} #{I18n.t('captain.custom_tool.headers.invalid')}")
  end

  def set_custom_tool
    @custom_tool = assistant_custom_tools.find(params[:id])
  end

  def assistant_custom_tools
    @assistant_custom_tools ||= Current.account.captain_assistants.find(params[:assistant_id]).custom_tools
  end

  def execute_test_request(tool)
    http_tool = Captain::Tools::HttpTool.new(nil, tool)
    http_tool.send(:execute_http_request, tool.endpoint_url, nil, nil)
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
      headers: {},
      param_schema: [:name, :type, :description, :required]
    )
  end
end
