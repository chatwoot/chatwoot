class SendBspdCallLogJob < ApplicationJob
  queue_as :high

  def perform(parsed_body, conversation, account_id)
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

  def build_call_report(parsed_body, conversation, account_id)
    is_inbound = parsed_body['Direction'] == 'inbound'
    journey_context = conversation.additional_attributes[:source_context]
    {
      conversationId: conversation.display_id,
      accountId: account_id.to_i,
      sender: parsed_body['From'],
      recipient: parsed_body['To'],
      senderCallStatus: is_inbound ? parsed_body['Legs'].last['Status'] : parsed_body['Legs'].first['Status'],
      recipientCallStatus: is_inbound ? parsed_body['Legs'].first['Status'] : parsed_body['Legs'].last['Status'],
      exotel: build_exotel_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(journey_context)
    }.compact
  end

  def build_exotel_data(parsed_body)
    {
      callId: parsed_body['CallSid'],
      accountId: parsed_body['PhoneNumberSid'],
      phoneNumber: parsed_body['From']
    }
  end

  def build_metadata(parsed_body)
    {
      direction: parsed_body['Direction'],
      eventType: parsed_body['EventType'],
      status: parsed_body['Status']
    }
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: parsed_body['StartTime'],
      callCompletedAt: parsed_body['EndTime'],
      onCallDuration: parsed_body['ConversationDuration']
    }
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['RecordingUrl'].blank?

    { url: parsed_body['RecordingUrl'] }
  end

  def build_journey_context(source_context)
    return nil if source_context.blank?

    {
      id: source_context['journeyId'],
      blockId: source_context['blockId'],
      customerJourneyId: source_context['customerJourneyId']
    }
  end
end
