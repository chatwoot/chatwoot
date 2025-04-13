module CallOzonetelHelper # rubocop:disable Metrics/ModuleLength
  include CallIvrsolutionsHelper

  ATTENDED = 'answered'.freeze
  NOT_ATTENDED = 'not_answered'.freeze

  def get_call_log_string_ozonetel(parsed_body)
    agent_attended = parsed_body['AgentStatus']
    customer_attended = parsed_body['CustomerStatus']
    call_duration = convert_duration_to_seconds(parsed_body['CallDuration'] || 0)

    case [agent_attended, customer_attended]
    when [ATTENDED, ATTENDED]
      "Call completed with user\n\nCall Duration: #{call_duration} sec\nCall recording link: #{parsed_body['AudioFile']}\nCall Id: #{parsed_body['monitorUCID']}" # rubocop:disable Layout/LineLength
    when [ATTENDED, NOT_ATTENDED]
      "Call was connected to agent but user didn't pick up the call"
    else
      "The call failed, as it couldn't be connected to the user and agent."
    end
  end

  def convert_duration_to_seconds(duration_str)
    hours, minutes, seconds = duration_str.strip.split(':').map(&:to_i)
    # Convert to total seconds
    (hours * 3600) + (minutes * 60) + seconds
  end

  def build_call_report_ozonetel(parsed_body, conversation, account)
    {
      conversationId: conversation.display_id,
      accountId: account.id.to_i,
      sender: determine_sender(parsed_body),
      recipient: determine_recipient(parsed_body),
      senderCallStatus: determine_sender_status(parsed_body),
      recipientCallStatus: determine_recipient_status(parsed_body),
      external: build_ozonetel_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(conversation&.additional_attributes&.dig('source_context') || {})
    }.compact
  end

  def determine_sender(parsed_body)
    is_inbound = parsed_body['DialStatus'].start_with?('0')
    if is_inbound
      parsed_body['CallerID']
    else
      parsed_body['AgentPhoneNumber']
    end
  end

  def determine_recipient(parsed_body)
    is_inbound = parsed_body['DialStatus'].start_with?('0')
    if is_inbound
      parsed_body['AgentPhoneNumber']
    else
      parsed_body['CallerID']
    end
  end

  def determine_sender_status(parsed_body) # rubocop:disable Metrics/MethodLength
    is_inbound = parsed_body['DialStatus'].start_with?('0')
    if is_inbound
      case parsed_body['CustomerStatus']
      when 'answered'
        'completed'
      when 'not_answered'
        'no-answer'
      when 'Busy'
        'busy'
      else
        'failed'
      end
    else
      case parsed_body['AgentStatus']
      when 'answered'
        'completed'
      when 'Busy'
        'busy'
      else
        'failed'
      end
    end
  end

  def determine_recipient_status(parsed_body) # rubocop:disable Metrics/MethodLength
    is_inbound = parsed_body['DialStatus'].start_with?('0')
    if is_inbound
      case parsed_body['AgentStatus']
      when 'answered'
        'completed'
      when 'not_answered'
        'no-answer'
      when 'Busy'
        'busy'
      else
        'failed'
      end
    else
      case parsed_body['CustomerStatus']
      when 'answered'
        'completed'
      when 'Busy'
        'busy'
      else
        'failed'
      end
    end
  end

  def build_ozonetel_data(parsed_body)
    {
      callId: parsed_body['monitorUCID'],
      accountId: parsed_body['Did'],
      phoneNumber: parsed_body['Did']
    }
  end

  def build_metadata(parsed_body)
    is_inbound = parsed_body['DialStatus'].start_with?('0')
    if is_inbound
      {
        direction: 'inbound',
        eventType: 'terminal',
        status: determine_call_status(parsed_body)
      }
    else
      {
        direction: 'outbound-api',
        eventType: 'terminal',
        status: determine_call_status(parsed_body)
      }
    end
  end

  def determine_call_status(parsed_body)
    case parsed_body['Status']
    when 'Answered'
      'completed'
    when 'NotAnswered'
      'no-answer'
    else
      'failed'
    end
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: Time.parse(parsed_body['StartTime']).in_time_zone('Asia/Kolkata'),
      callCompletedAt: Time.parse(parsed_body['EndTime']).in_time_zone('Asia/Kolkata'),
      onCallDuration: convert_duration_to_seconds(parsed_body['CallDuration'] || 0)
    }
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['AudioFile'].blank?

    { url: parsed_body['AudioFile'] }
  end
end
