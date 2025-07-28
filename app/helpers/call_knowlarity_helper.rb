module CallKnowlarityHelper # rubocop:disable Metrics/ModuleLength
  include CallIvrsolutionsHelper

  def get_call_log_string_knowlarity(parsed_body) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    destination = parsed_body['destination']
    recording_url = parsed_body['resource_url']
    call_id = parsed_body['callid']

    if destination == 'Customer Missed'
      'Agent called customer, but the customer did not pick up the call.'
    elsif destination == 'Agent Missed'
      'Agent did not pick up the call.'
    elsif destination.present? && destination != 'Customer Missed' && destination != 'Agent Missed' && call_duration > 1
      "Call completed with user\n\nCall Duration: #{call_duration} sec\nCall recording link: #{recording_url}\nCall Id: #{call_id}"
    else
      "The call failed, as it couldn't be connected to the user and agent."
    end
  end

  def convert_duration_to_seconds(duration)
    return 0 if duration.blank?

    return duration.to_i if /^\d+$/.match?(duration.to_s)

    hours, minutes, seconds = duration.strip.split(':').map(&:to_i)
    (hours * 3600) + (minutes * 60) + seconds
  end

  def build_call_report_knowlarity(parsed_body, conversation, account)
    {
      conversationId: conversation.display_id,
      accountId: account.id.to_i,
      sender: determine_sender(parsed_body),
      recipient: determine_recipient(parsed_body),
      senderCallStatus: determine_sender_status(parsed_body),
      recipientCallStatus: determine_recipient_status(parsed_body),
      external: build_knowlarity_data(parsed_body),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(conversation&.additional_attributes&.dig('source_context') || {})
    }.compact
  end

  def determine_sender(parsed_body)
    parsed_body['caller_id']
  end

  def determine_recipient(parsed_body)
    is_inbound = parsed_body['call_type'] == 'incoming'
    if is_inbound
      parsed_body['customer_missed_number'].presence || parsed_body['caller_id']
    else
      parsed_body['customer_missed_number'].presence || parsed_body['destination']
    end
  end

  def determine_sender_status(parsed_body)
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    destination = parsed_body['destination']
    if ['Customer Missed', 'Agent Missed'].include?(destination)
      'no-answer'
    elsif destination.present? && destination != 'Customer Missed' && destination != 'Agent Missed' && call_duration > 1
      'completed'
    else
      'failed'
    end
  end

  def determine_recipient_status(parsed_body)
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    destination = parsed_body['destination']
    if ['Customer Missed', 'Agent Missed'].include?(destination)
      'no-answer'
    elsif destination.present? && destination != 'Customer Missed' && destination != 'Agent Missed' && call_duration > 1
      'completed'
    else
      'failed'
    end
  end

  def build_knowlarity_data(parsed_body)
    {
      callId: parsed_body['callid'],
      accountId: parsed_body['dispnumber'],
      phoneNumber: parsed_body['dispnumber']
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
    destination = parsed_body['destination']
    call_duration = convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    if ['Customer Missed', 'Agent Missed'].include?(destination)
      'no-answer'
    elsif destination.present? && destination != 'Customer Missed' && destination != 'Agent Missed' && call_duration > 1
      'completed'
    else
      'failed'
    end
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: Time.parse(parsed_body['start_time']).in_time_zone,
      callCompletedAt: Time.parse(parsed_body['end_time']).in_time_zone,
      onCallDuration: convert_duration_to_seconds(parsed_body['call_duration'] || 0)
    }
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['resource_url'].blank?

    { url: parsed_body['resource_url'] }
  end
end
