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

  def update_call_report
    unless params[:callId].present? && params[:account_id].present?
      render json: { error: 'callId or phone number are required parameters' }, status: :bad_request
      return
    end

    url = 'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/callLogs/update'
    body = build_request_body

    response = HTTParty.patch(url, body: body, headers: { 'Content-Type' => 'application/json' })

    if response.success?
      render json: response.body
    else
      Rails.logger.error("Update call report API error: #{response.code} - #{response.body}")
      render json: { error: 'Failed to update call report' }, status: response.code
    end
  rescue StandardError => e
    handle_error(e)
  end

  def export_call_report # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    unless params[:email].present? && params[:account_id].present?
      render json: { error: 'email and account ID are required parameters' }, status: :bad_request
      return
    end

    url = 'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/callLogs/export'
    body = {
      startDate: params[:startDate],
      endDate: params[:endDate],
      accountId: params[:account_id],
      email: params[:email]
    }.to_json
    Rails.logger.info("JSON Body, #{body.inspect}")

    response = HTTParty.post(url, body: body, headers: { 'Content-Type' => 'application/json' })
    Rails.logger.info("Response, #{response.inspect}")
    if response.success?
      render json: response.body
    else
      Rails.logger.error("Error Exporting call report: #{response.code} - #{response.body}")
      render json: { error: 'Failed to Export call report' }, status: response.code
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def fetch_and_render_call_logs
    # url = 'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/callLogs?accountId=966&phoneNumber=917207414297'
    url = "https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/callLogs?accountId=#{params[:account_id]}&phoneNumber=#{params[:phone_number]}"
    response = HTTParty.get(url)

    if response.success?
      render json: response.body
    else
      Rails.logger.error("Call logs API error: #{response.code} - #{response.body}")
      render json: { error: 'Failed to fetch call logs' }, status: response.code
    end
  end

  def build_request_body
    body = { account_id: params[:account_id], callId: params[:callId] }
    body[:agentCallStatus] = params[:agentCallStatus] if params[:agentCallStatus].present? || params[:agentCallStatus] == ''
    body[:agentCallNote] = params[:agentCallNote] if params[:agentCallNote].present? || params[:agentCallNote] == ''
    body.to_json
  end

  def handle_error(error)
    Rails.logger.error("Call logs request failed: #{error.message}")
    render json: { error: 'Service temporarily unavailable' }, status: :service_unavailable
  end
end
