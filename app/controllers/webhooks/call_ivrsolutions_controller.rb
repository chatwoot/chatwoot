require 'json'
require 'httparty'

class Webhooks::CallIvrsolutionsController < ActionController::API
  include CallIvrsolutionsHelper

  def handle_call_callback
    parsed_body = parse_request_body

    account = find_account(parsed_body)
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    contact = find_contact(account, parsed_body)
    return render json: { error: 'Contact not found' }, status: :not_found if contact.blank?

    conversation = find_latest_conversation(contact, account)
    return render json: { error: 'Conversation not found' }, status: :not_found if conversation.blank?

    create_call_log_message(conversation, parsed_body)
    send_call_log_to_bspd(parsed_body, conversation, account)

    head :ok
  end

  private

  def parse_request_body
    JSON.parse(request.body.read)
  end

  def find_account(parsed_body)
    did_no = parsed_body['did_no'].gsub(/^\+/, '')
    Account.where("custom_attributes->>'call_config' IS NOT NULL")
           .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'did' = ?", did_no)
  end

  def find_contact(account, parsed_body)
    is_c2c = parsed_body['call_type'] == 'c2c'
    Rails.logger.info("is_c2c, #{is_c2c}")
    client_no = is_c2c ? parsed_body['client_no'].gsub(/^0/, '+91') : parsed_body['outgoing_ext'].gsub(/^0/, '+91')
    Contact.find_by(account_id: account.id, phone_number: client_no)
  end

  def find_latest_conversation(contact, account)
    Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first
  end

  def create_call_log_message(conversation, parsed_body)
    call_log_message = get_call_log_string_ivr(parsed_body)
    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))
  end

  def private_message_params(content, conversation, parsed_body)
    time = Time.zone.parse(parsed_body['call_time'])
    new_time = time - ((5 * 3600) + (30 * 60))
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content, private: true,
      content_attributes: { external_created_at: new_time.to_i }
    }
  end

  def send_call_log_to_bspd(parsed_body, conversation, account)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report_ivr_outbound(parsed_body, conversation, account)
    Rails.logger.info "Call log sent to BSPD: #{call_report.to_json}"
    send_report_to_bspd(call_report)
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
