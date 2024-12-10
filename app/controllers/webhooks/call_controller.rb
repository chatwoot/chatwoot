# app/controllers/webhooks/call_controller.rb
require 'json'
require 'httparty'

class Webhooks::CallController < ActionController::API
  include CallHelper
  def handle_call_callback
    payload = request.body.read
    parsed_body = JSON.parse(payload)

    conversation = Conversation.where({
                                        account_id: params[:account_id],
                                        inbox_id: params[:inbox_id],
                                        display_id: params[:conversation_id]
                                      }).first

    send_call_log_to_bspd(parsed_body, conversation, params[:account_id])

    call_log_message = get_call_log_string(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation))

    head :ok
  end

  def private_message_params(content, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: content, private: true }
  end

  private

  def send_call_log_to_bspd(parsed_body, conversation, account_id)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report(parsed_body, conversation, account_id)
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

  def handle_error(error)
    Rails.logger.error "Error sending call log to BSPD: #{error.message}"
    raise error
  end
end
