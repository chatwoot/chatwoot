require 'securerandom'

module AddCallLogHelper
  def build_call_report(parsed_body, conversation, contact, account_id)
    is_inbound = parsed_body['isInbound']
    journey_context = conversation&.additional_attributes&.dig('source_context') || {}
    {
      conversationId: conversation.display_id,
      accountId: account_id.to_i,
      sender: is_inbound ? contact.phone_number : parsed_body['agentPhoneNo'],
      recipient: is_inbound ? parsed_body['agentPhoneNo'] : contact.phone_number,
      senderCallStatus: 'completed',
      recipientCallStatus: 'completed',
      external: build_external_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(journey_context),
      agentCallStatus: parsed_body['callStatus'],
      agentCallNote: parsed_body['callNote']
    }.compact
  end

  def build_external_data(parsed_body)
    {
      callId: generate_unique_call_id,
      accountId: parsed_body['agentPhoneNo'],
      phoneNumber: parsed_body['agentPhoneNo']
    }
  end

  def build_metadata(parsed_body)
    is_inbound = parsed_body['isInbound']
    {
      direction: is_inbound ? 'inbound' : 'outbound-dial',
      eventType: 'terminal',
      status: 'manual'
    }
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: parsed_body['date'],
      onCallDuration: parsed_body['callDuration'].to_i * 60
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

  def generate_unique_call_id
    "#{Time.now.to_i}-#{SecureRandom.random_number(1000)}"
  end
end
