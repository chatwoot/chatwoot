# frozen_string_literal: true

# [whisker] Public client error ingestion endpoint
# Widgets run on third-party sites; this accepts anonymous error reports
# keyed by website_token so self-hosters can debug client issues.
class Api::V1::ClientErrorReportsController < Api::BaseController
  skip_before_action :authenticate_access_token!, only: [:create]
  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :validate_bot_access_token!, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    report = ClientErrorReport.new(report_params)
    report.account = find_account
    report.user_agent = request.user_agent
    report.environment = Rails.env.to_s
    report.app_version = Whisker.version

    if report.save
      head :ok
    else
      render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_account
    token = params[:website_token]
    return nil if token.blank?

    Channel::WebWidget.find_by!(website_token: token)&.account
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def report_params
    params.require(:client_error_report).permit(
      :website_token, :platform, :message, :stack, :url, metadata: {}
    )
  end
end
