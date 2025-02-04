# rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ModuleLength
module CallHelper
  def get_call_log_string(callback_payload)
    agent_log = callback_payload['Legs'].first
    user_log = callback_payload['Legs'].last
    agent_call_status = agent_log['Status']
    user_call_status = user_log['Status']
    event_type = callback_payload['EventType']

    case event_type
    when 'terminal'
      return 'Call was connected to agent but they were busy' if agent_call_status == 'busy'
      return "Call was connected to agent but they didn't pick up the call" if agent_call_status == 'no-answer'
      return "The call failed, as it couldn't be connected to the user." if callback_payload['Status'] == 'failed' && user_call_status == 'canceled'

      if callback_payload['Status'] == 'completed'
        call_duration = format_duration_from_seconds(user_log['OnCallDuration'])
        "Call completed with user\n\nCall Duration: #{call_duration}\nCall recording link: #{callback_payload['RecordingUrl']}"
      end
    when 'answered'
      if agent_call_status == 'in-progress' && user_call_status == 'in-progress'
        'Both user and agent are on the call'
      elsif agent_call_status == 'in-progress'
        'Agent has picked up the call'
      end
    end
  end

  def format_duration_from_seconds(duration_seconds)
    hours = duration_seconds / 3600
    minutes = (duration_seconds % 3600) / 60
    remaining_seconds = duration_seconds % 60

    result = []
    result << "#{hours} hours" if hours.positive?
    result << "#{minutes} minutes" if minutes.positive?
    result << "#{remaining_seconds} seconds" if remaining_seconds.positive?

    result.join(' ')
  end

  def build_call_report(parsed_body, conversation, account_id)
    is_inbound = parsed_body['Direction'] == 'inbound'
    journey_context = conversation&.additional_attributes&.dig('source_context') || {}
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
      phoneNumber: parsed_body['PhoneNumberSid']
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

  def get_on_call_duration(legs)
    total_duration = 0
    legs = legs.values
    legs.each do |leg|
      total_duration += leg['OnCallDuration'].to_i
    end

    total_duration
  end

  def get_inbound_call_log_string(call_status, legs, recording_url)
    case call_status
    when 'busy'
      'Call was connected but the recipient was busy'
    when 'no-answer'
      "Call was connected but recipient didn't pick up the call"
    when 'failed'
      'The call failed to connect'
    when 'completed'
      call_duration = format_duration_from_seconds(legs['0']['OnCallDuration'].to_i)
      "Inbound Call completed\n\nCall Duration: #{call_duration}#{recording_url.present? ? "\nCall recording link: #{recording_url}" : ''}"
    when 'in-progress'
      'Call is currently in progress'
    else
      'Unknown call status'
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ModuleLength
