class Api::V1::Accounts::ParquetReportsController < Api::V1::Accounts::BaseController
  def show
    report = ParquetReport.find(params[:id])
    render json: { progress: report.progress, status: report.status, file_url: report.file_url }
  end
end