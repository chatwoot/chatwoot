class V2::LabelReportBuilder
  include DateRangeHelper
  include ReportHelper
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]&.name
  end

  def build; end
end
