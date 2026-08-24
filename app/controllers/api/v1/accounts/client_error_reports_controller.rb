# frozen_string_literal: true

# [whisker] Account-scoped client error reports for debugging
class Api::V1::Accounts::ClientErrorReportsController < Api::V1::Accounts::BaseController
  def index
    @reports = current_account
      .client_error_reports
      .recent
      .page(params[:page] || 1)
      .per(params[:per_page] || 50)
  end

  def show
    @report = current_account.client_error_reports.find(params[:id])
  end
end
