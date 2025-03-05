module CallIvrsolutionsHelper # rubocop:disable Metrics/ModuleLength
  ATTENDED = '1'.freeze
  NOT_ATTENDED = '0'.freeze

  def get_call_log_string_ivr(parsed_body) # rubocop:disable Metrics/MethodLength
    is_c2c = parsed_body['call_type'] == 'c2c'
    agent_attended = parsed_body['agent_attended']
    customer_attended = parsed_body['customer_attended']
    call_duration = parsed_body['call_duration']

    if is_c2c
      case [agent_attended, customer_attended]
      when [ATTENDED, ATTENDED]
        "Call completed with user\n\nCall Duration: #{call_duration}\nCall recording link: #{parsed_body['recording_url']}"
      when [ATTENDED, NOT_ATTENDED]
        "The call failed, as it couldn't be connected to the user."
      when [NOT_ATTENDED, NOT_ATTENDED], [NOT_ATTENDED, ATTENDED]
        "Call was connected to agent but they didn't pick up the call"
      else
        "The call failed, as it couldn't be connected to the user and agent."
      end
    else
      case call_duration
      when '0'
        "The call failed, as it couldn't be connected to the user."
      else
        "Call completed with user\n\nCall Duration: #{call_duration}\nCall recording link: #{parsed_body['recording_url']}"
      end
    end
  end

  def build_call_report_ivr_outbound(parsed_body, conversation, account)
    is_c2c = parsed_body['call_type'] == 'c2c'
    {
      conversationId: conversation.display_id,
      accountId: account.id.to_i,
      sender: determine_sender(parsed_body, account, is_c2c),
      recipient: determine_recipient(parsed_body, is_c2c),
      senderCallStatus: determine_sender_status(parsed_body, is_c2c),
      recipientCallStatus: determine_recipient_status(parsed_body, is_c2c),
      external: build_ivrsolutions_data(parsed_body, account.id),
      metadata: build_metadata(parsed_body),
      timing: build_timing_data(parsed_body),
      recording: build_recording_data(parsed_body),
      journeyContext: build_journey_context(conversation&.additional_attributes&.dig('source_context') || {})
    }.compact
  end

  private

  def determine_sender(parsed_body, account, is_c2c)
    is_c2c ? parsed_body['agent_no'] : find_sender_number_by_ext_no(parsed_body, account)
  end

  def determine_recipient(parsed_body, is_c2c)
    is_c2c ? parsed_body['client_no'] : parsed_body['outgoing_ext']
  end

  def determine_sender_status(parsed_body, is_c2c)
    return 'completed' unless is_c2c

    parsed_body['agent_attended'] == ATTENDED ? 'completed' : 'failed'
  end

  def determine_recipient_status(parsed_body, is_c2c)
    if is_c2c
      parsed_body['customer_attended'] == ATTENDED ? 'completed' : 'failed'
    else
      determine_softphone_status(parsed_body['call_duration'])
    end
  end

  def build_timing_data(parsed_body)
    {
      callInitiatedAt: parsed_body['call_time'],
      onCallDuration: parsed_body['call_duration']
    }
  end

  def build_ivrsolutions_data(parsed_body, account_id)
    {
      callId: parsed_body['recordid'],
      accountId: account_id,
      phoneNumber: parsed_body['did_no'].gsub(/^\+/, '')
    }
  end

  def build_recording_data(parsed_body)
    return nil if parsed_body['recording_url'].blank?

    { url: parsed_body['recording_url'] }
  end

  def build_metadata(parsed_body)
    {
      direction: 'outbound-api',
      eventType: 'terminal',
      status: determine_call_status(parsed_body)
    }
  end

  def determine_call_status(parsed_body)
    if parsed_body['call_type'] == 'c2c'
      determine_c2c_status(parsed_body)
    else
      determine_softphone_status(parsed_body['call_duration'])
    end
  end

  def determine_c2c_status(parsed_body)
    case [parsed_body['agent_attended'], parsed_body['customer_attended']]
    when [ATTENDED, ATTENDED] then 'completed'
    when [ATTENDED, NOT_ATTENDED] then 'busy'
    else 'failed'
    end
  end

  def determine_softphone_status(call_duration)
    call_duration == '0' ? 'failed' : 'completed'
  end

  def build_journey_context(source_context)
    return nil if source_context.blank?

    {
      id: source_context['journeyId'],
      blockId: source_context['blockId'],
      customerJourneyId: source_context['customerJourneyId']
    }
  end

  def find_sender_number_by_ext_no(parsed_body, account) # rubocop:disable Metrics/CyclomaticComplexity
    ext_no_agent = parsed_body['client_no']
    call_config = account&.custom_attributes&.[]('call_config')
    # Get the mapping hash
    ext_mapping = call_config.dig('externalProviderConfig', 'extNoMapping')
    return nil if ext_mapping.blank?

    # Find the phone number (key) by extension (value)
    phone_number = ext_mapping.find { |_phone, ext| ext == ext_no_agent }&.first
    phone_number = "0#{phone_number}" unless phone_number.nil? || phone_number.start_with?('0')

    phone_number
  end
end
