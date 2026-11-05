class Api::V1::Accounts::Captain::CustomToolsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }
  before_action :set_current_page, only: [:index]
  before_action :set_custom_tool, only: [:show, :update, :destroy]
  before_action :validate_headers_param, only: [:create, :update, :test]
  before_action :validate_settings_param, only: [:create, :update]
  before_action :validate_param_schema_param, only: [:create, :update]

  PARAM_FIELDS = %w[name type description required source].freeze

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
    # Tools installed from a manifest are managed by their manifest. Only the user-owned enabled flag and settings can change.
    if @custom_tool.source_metadata.present? && (custom_tool_params.keys - %w[enabled settings]).any?
      return render_could_not_create_error(I18n.t('captain.custom_tool.installed_read_only'))
    end

    @custom_tool.update!(custom_tool_params.merge(merged_settings))
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
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  # permit(headers: {}) silently drops non-object values, so reject them before they are filtered out
  def validate_headers_param
    return unless params[:custom_tool]&.key?(:headers)
    return if params[:custom_tool][:headers].is_a?(ActionController::Parameters)

    render_could_not_create_error("#{Captain::CustomTool.human_attribute_name(:headers)} #{I18n.t('captain.custom_tool.headers.invalid')}")
  end

  # permit silently drops unknown keys and non-object values, so a misspelled setting would look saved and leave the tool unprotected
  def validate_settings_param
    return unless params[:custom_tool]&.key?(:settings)

    settings = params[:custom_tool][:settings]
    return render_settings_error(I18n.t('captain.custom_tool.settings.invalid')) unless settings.is_a?(ActionController::Parameters)

    unknown_keys = settings.keys - Captain::CustomTool::SETTING_KEYS
    return render_settings_error(I18n.t('captain.custom_tool.settings.unknown', names: unknown_keys.join(', '))) if unknown_keys.any?

    # permit drops a nested value, so it would save as off instead of failing
    render_settings_error(I18n.t('captain.custom_tool.settings.not_boolean')) unless settings.values.all? { |value| [true, false].include?(value) }
  end

  # permit drops a nested value or an unknown field, so a parameter meant to take a verified value would save as one the model fills
  def validate_param_schema_param
    return unless params[:custom_tool]&.key?(:param_schema)

    param_schema = params[:custom_tool][:param_schema]
    return if param_schema.is_a?(Array) && param_schema.all? { |param_def| plain_param?(param_def) }

    render_could_not_create_error(
      "#{Captain::CustomTool.human_attribute_name(:param_schema)} #{I18n.t('captain.custom_tool.param_schema.invalid')}"
    )
  end

  def plain_param?(param_def)
    param_def.is_a?(ActionController::Parameters) && (param_def.keys - PARAM_FIELDS).empty? &&
      param_def.values.all? { |value| value.is_a?(String) || value.is_a?(Numeric) || [true, false, nil].include?(value) }
  end

  def render_settings_error(message)
    render_could_not_create_error("#{Captain::CustomTool.human_attribute_name(:settings)} #{message}")
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

  # Settings sent in an update are merged into the saved ones, so a partial update can never drop a setting
  def merged_settings
    return {} unless custom_tool_params.key?(:settings)

    { settings: @custom_tool.settings.merge(custom_tool_params[:settings]) }
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
      settings: Captain::CustomTool::SETTING_KEYS,
      param_schema: PARAM_FIELDS.map(&:to_sym)
    )
  end
end
