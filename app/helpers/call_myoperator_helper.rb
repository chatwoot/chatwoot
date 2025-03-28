module CallMyoperatorHelper # rubocop:disable Metrics/ModuleLength
  include CallIvrsolutionsHelper

  def get_call_log_string_my_operator(parsed_body)
    status_log = parsed_body['status_log']
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)

    case status_log
    when 'connected'
      "Call completed with user\n\nCall Duration: #{call_duration} sec\nCall recording link: #{parsed_body['recording_url']}\nCall Id: #{parsed_body['uid']}" # rubocop:disable Layout/LineLength
    when 'missed'
      "Call was connected to agent but agent or user didn't pick up the call"
    else
      "The call failed, as it couldn't be connected to the user and agent."
    end
  end

  def convert_duration_to_seconds(duration_str)
    hours, minutes, seconds = duration_str.strip.split(':').map(&:to_i)
    # Convert to total seconds
    (hours * 3600) + (minutes * 60) + seconds
  end

  def build_call_report_myoperator(parsed_body, conversation, account)
    {
      conversationId: conversation.display_id,
      accountId: account.id.to_i,
      sender: determine_sender(parsed_body),
      recipient: determine_recipient(parsed_body),
      senderCallStatus: determine_sender_status(parsed_body),
      recipientCallStatus: determine_recipient_status(parsed_body),
      external: build_myoperator_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(conversation&.additional_attributes&.dig('source_context') || {})
    }.compact
  end

  def determine_sender(parsed_body)
    case parsed_body['event_log']
    when 'outgoing'
      parsed_body['agent_number']
    when 'incoming'
      parsed_body['phone_number']
    end
  end

  def determine_recipient(parsed_body)
    case parsed_body['event_log']
    when 'outgoing'
      parsed_body['phone_number']
    when 'incoming'
      parsed_body['agent_number']
    end
  end

  def determine_sender_status(parsed_body)
    case parsed_body['status_log']
    when 'connected'
      'completed'
    when 'missed'
      'busy'
    end
  end

  def determine_recipient_status(parsed_body)
    case parsed_body['status_log']
    when 'connected'
      'completed'
    when 'missed'
      'no-answer'
    end
  end

  def build_myoperator_data(parsed_body)
    {
      callId: parsed_body['uid'],
      accountId: parsed_body['company_id'],
      phoneNumber: parsed_body['uid']
    }
  end

  def build_metadata(parsed_body)
    case parsed_body['event_log']
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
    case parsed_body['status_log']
    when 'connected'
      'completed'
    when 'missed'
      'no-answer'
    else
      'failed'
    end
  end

  def build_timing_data(parsed_body)
    data = {
      callInitiatedAt: Time.at(parsed_body['call_start'].to_i).in_time_zone,
      callCompletedAt: Time.at(parsed_body['call_end'].to_i).in_time_zone,
      onCallDuration: convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    }
    Rails.logger.info("timingData, #{data}")
    data
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['recording_url'].blank?

    { url: parsed_body['recording_url'] }
  end
end
