class Api::V1::CallLogsController < ApplicationController
  def index
    unless params[:account_id].present? && params[:phone_number].present?
      render json: { error: 'account_id and phone_number are required parameters' }, status: :bad_request
      return
    end

    fetch_and_render_call_logs
  rescue StandardError => e
    handle_error(e)
  end

  private

  def fetch_and_render_call_logs
    url = "https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/callLogs?accountId=#{params[:account_id]}&phoneNumber=#{params[:phone_number]}"
    response = HTTParty.get(url)

    if response.success?
      render json: response.body
    else
      Rails.logger.error("Call logs API error: #{response.code} - #{response.body}")
      render json: { error: 'Failed to fetch call logs' }, status: response.code
    end
  end

  def handle_error(error)
    Rails.logger.error("Call logs request failed: #{error.message}")
    render json: { error: 'Service temporarily unavailable' }, status: :service_unavailable
  end
end
