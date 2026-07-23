class Api::V1::Accounts::SavedReportPanelsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_panel, only: [:show, :update, :destroy, :run, :export]

  def index
    @panels = Current.account.saved_report_panels.ordered
  end

  def show; end

  def create
    @panel = Current.account.saved_report_panels.create!(
      panel_params.merge(created_by: Current.user)
    )
  end

  def update
    @panel.update!(panel_params)
  end

  def destroy
    @panel.destroy!
    head :no_content
  end

  def run
    render json: build_runner.perform
  end

  def export
    result = build_runner.perform

    xlsx_data = Reports::PanelExportService.new(result).to_xlsx
    send_data xlsx_data,
              filename: ExportFilename.build(
                account: Current.account,
                resource: "panel-#{@panel.id}",
                extension: 'xlsx'
              ),
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  private

  def build_runner
    Reports::PanelRunnerService.new(
      panel: @panel,
      account: Current.account,
      user: Current.user,
      timezone_offset: params[:timezone_offset],
      since_override: params[:since],
      until_override: params[:until]
    )
  end

  def check_authorization
    authorize :report, :view?
  end

  def fetch_panel
    @panel = Current.account.saved_report_panels.find(params[:id])
  end

  def panel_params
    raw = params.require(:saved_report_panel)
    attrs = {}
    attrs[:name] = raw[:name] if raw.key?(:name)
    attrs[:description] = raw[:description] if raw.key?(:description)
    attrs[:date_preset] = raw[:date_preset] if raw.key?(:date_preset)
    attrs[:custom_since] = cast_unix(raw[:custom_since]) if raw.key?(:custom_since)
    attrs[:custom_until] = cast_unix(raw[:custom_until]) if raw.key?(:custom_until)
    attrs[:filters] = normalize_json_array(raw[:filters]) if raw.key?(:filters)
    attrs[:widgets] = normalize_json_array(raw[:widgets]) if raw.key?(:widgets)
    attrs[:business_hours] = ActiveModel::Type::Boolean.new.cast(raw[:business_hours]) if raw.key?(:business_hours)
    attrs[:favorite] = ActiveModel::Type::Boolean.new.cast(raw[:favorite]) if raw.key?(:favorite)
    attrs
  end

  def cast_unix(value)
    return nil if value.blank?

    value.to_i
  end

  def normalize_json_array(value)
    return [] if value.nil?

    Array(value).filter_map do |item|
      next item if item.is_a?(Hash)
      next item.to_unsafe_h if item.respond_to?(:to_unsafe_h)
      next item.to_h if item.respond_to?(:to_h)

      nil
    end
  end
end
