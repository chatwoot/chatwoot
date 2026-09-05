module Api::V2::Accounts::ReportResponseFormatter
  extend ActiveSupport::Concern

  private

  def respond_with_report_download(filename, template)
    respond_to do |format|
      format.csv  { generate_csv(filename, template) }
      format.xlsx { generate_xlsx(filename, template) }
      format.any  { generate_csv(filename, template) }
    end
  end

  def generate_csv(filename, template)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"
    render layout: false, template: template, formats: [:csv]
  end

  def generate_xlsx(filename, template)
    response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    response.headers['Content-Disposition'] = "attachment; filename=#{filename}.xlsx"
    render layout: false, template: template, formats: [:xlsx]
  end

  def report_service
    @report_service ||= Api::V2::Accounts::ReportGenerationService.new(Current.account, params, current_user)
  end
end
