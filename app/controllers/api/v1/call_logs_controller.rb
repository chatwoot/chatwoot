class Api::V1::CallLogsController < ApplicationController
  include AddCallLogHelper
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

  def create_call_log # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    payload = request.body.read
    parsed_body = JSON.parse(payload)

    unless params[:callStatus].present? && params[:callNote].present? && params[:date].present?
      render json: { error: 'Call Status, Call note, date are required parameters' }, status: :bad_request
      return
    end

    unless params[:account_id].present? && params[:inboxId].present? && params[:conversationId].present? && params[:contactId].present?
      render json: { error: 'Account Id, conversation Id, Inbox Id are required' }, status: :bad_request
      return
    end

    contact = Contact.find_by(id: params[:contactId])
    return render json: { error: 'Contact not found' }, status: :not_found if contact.blank?

    conversation = Conversation.where({
                                        account_id: params[:account_id],
                                        inbox_id: params[:inboxId],
                                        display_id: params[:conversationId]
                                      }).first

    send_call_log_to_bspd(parsed_body, conversation, contact, params[:account_id])
    head :ok
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

  def send_call_log_to_bspd(parsed_body, conversation, contact, account_id)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report(parsed_body, conversation, contact, account_id)
    send_report_to_bspd(call_report)
    Rails.logger.info "Call log sent to BSPD: #{call_report.inspect}"
  rescue StandardError => e
    handle_error(e)
  end

  def send_report_to_bspd(call_report)
    response = HTTParty.post(
      'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/webhook/callReport',
      body: call_report.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    handle_response(response)
  end

  def handle_response(response)
    unless response.success?
      Rails.logger.error "BSPD API returned error: #{response.body}"
      raise "BSPD API error: #{response.code} - #{response.body}"
    end
    Rails.logger.info "Call log sent to BSPD: #{response.body}"
  end
end
