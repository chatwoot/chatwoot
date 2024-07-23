class Api::V1::Accounts::ParquetReportsController < Api::V1::Accounts::BaseController
  def show
    report = ParquetReport.find(params[:id])
    render json: report.progress_json
  end
end