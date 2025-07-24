module CallAlohaaHelper # rubocop:disable Metrics/ModuleLength
  include CallIvrsolutionsHelper

  def get_call_log_string_alohaa(parsed_body)
    call_status = parsed_body['call_status']
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)

    case call_status
    when 'answered'
      "Call completed with user\n\nCall Duration: #{call_duration} sec\nCall recording link: #{parsed_body['call_recording_url']}\nCall Id: #{parsed_body['call_id']}" # rubocop:disable Layout/LineLength
    when 'notanswered'
      "Call was connected to agent but agent or user didn't pick up the call"
    else
      "The call failed, as it couldn't be connected to the user and agent."
    end
  end

  def convert_duration_to_seconds(duration)
    return duration if duration.is_a?(Integer)
    return 0 if duration.blank?

    hours, minutes, seconds = duration.strip.split(':').map(&:to_i)
    (hours * 3600) + (minutes * 60) + seconds
  end

  def build_call_report_alohaa(parsed_body, conversation, account)
    {
      conversationId: conversation.display_id,
      accountId: account.id.to_i,
      sender: determine_sender(parsed_body),
      recipient: determine_recipient(parsed_body),
      senderCallStatus: determine_sender_status(parsed_body),
      recipientCallStatus: determine_recipient_status(parsed_body),
      external: build_alohaa_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(conversation&.additional_attributes&.dig('source_context') || {})
    }.compact
  end

  def determine_sender(parsed_body)
    parsed_body['caller_number']
  end

  def determine_recipient(parsed_body)
    parsed_body['receiver_number']
  end

  def determine_sender_status(parsed_body)
    case parsed_body['hangup_cause']
    when 'initiator_hangup', 'receiver_hangup'
      'completed'
    when 'receiver_disconnected', 'initiator_disconnected'
      'no-answer'
    else
      'failed'
    end
  end

  def determine_recipient_status(parsed_body)
    case parsed_body['hangup_cause']
    when 'initiator_hangup', 'receiver_hangup'
      'completed'
    when 'receiver_disconnected', 'initiator_disconnected'
      'no-answer'
    else
      'failed'
    end
  end

  def build_alohaa_data(parsed_body)
    {
      callId: parsed_body['call_id'],
      accountId: parsed_body['did_number'],
      phoneNumber: parsed_body['did_number']
    }
  end

  def build_metadata(parsed_body)
    case parsed_body['call_type']
    when 'incoming'
      {
        direction: 'inbound',
        eventType: 'terminal',
        status: determine_call_status(parsed_body)
      }
    when 'outgoing'
      {
        direction: 'outbound-api',
        eventType: 'terminal',
        status: determine_call_status(parsed_body)
      }
    end
  end

  def determine_call_status(parsed_body)
    case parsed_body['call_status']
    when 'answered'
      'completed'
    when 'notanswered'
      'no-answer'
    else
      'failed'
    end
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: Time.parse(parsed_body['received_at']).in_time_zone,
      callCompletedAt: Time.parse(parsed_body['ended_at']).in_time_zone,
      onCallDuration: convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    }
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['call_recording_url'].blank?

    { url: parsed_body['call_recording_url'] }
  end
end
