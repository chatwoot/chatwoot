class Vapi::IncomingCallService
  pattr_initialize [:params!]

  def perform
    message_type = params[:message]&.[](:type) || params[:type]
    Rails.logger.info "Processing Vapi webhook: #{message_type}"

    case message_type
    when 'end-of-call-report'
      handle_end_of_call_report
    else
      Rails.logger.info "Ignoring Vapi webhook type: #{message_type} (only processing end-of-call-report)"
    end
  end

  private

  def handle_end_of_call_report
    return unless vapi_agent

    Rails.logger.info "Processing end-of-call for call_id: #{call_id}, agent: #{agent_id}"

    # Create conversation with formatted transcript
    create_call_summary_message
    store_full_call_metadata
  end

  def create_call_summary_message
    # Build formatted transcript from conversation messages
    transcript_messages = conversation_messages
    formatted_transcript = format_transcript(transcript_messages)

    # Create activity message for call start
    conversation.messages.create!(
      content: '📞 Call started',
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :activity,
      content_type: :text
    )

    # Create messages for each conversation turn
    transcript_messages.each do |msg|
      next if msg['role'] == 'system'

      msg_type = msg['role'] == 'bot' ? :outgoing : :incoming
      content = msg['message'] || msg['content']

      conversation.messages.create!(
        content: content,
        account_id: inbox.account_id,
        inbox_id: inbox.id,
        message_type: msg_type,
        sender: contact,
        content_type: :text,
        additional_attributes: {
          source: 'vapi',
          call_id: call_id,
          timestamp: msg['time']
        }
      )
    end

    # Create activity message for call end
    duration_text = duration.present? ? "Duration: #{format_duration(duration)}" : 'Call completed'
    end_content = "📞 Call ended - #{duration_text}"
    end_content += ' | Recording available' if recording_url.present?

    conversation.messages.create!(
      content: end_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :activity,
      content_type: :text,
      additional_attributes: {
        recording_url: recording_url
      }.compact
    )
  end

  def store_full_call_metadata
    conversation.update!(
      additional_attributes: conversation.additional_attributes.merge(
        vapi_call_id: call_id,
        vapi_agent_id: vapi_agent.vapi_agent_id,
        call_started_at: params.dig(:message, :call, :createdAt),
        call_ended_at: params.dig(:message, :call, :updatedAt),
        vapi_call_duration: duration,
        vapi_recording_url: recording_url,
        vapi_call_cost: params.dig(:message, :call, :cost)
      ).compact
    )
  end

  def conversation_messages
    params.dig(:message, :artifact, :messages) || []
  end

  def format_transcript(messages)
    messages.reject { |m| m['role'] == 'system' }.map do |msg|
      role = msg['role'] == 'bot' ? 'Assistant' : 'User'
      "#{role}: #{msg['message'] || msg['content']}"
    end.join("\n\n")
  end


  def vapi_agent
    @vapi_agent ||= find_vapi_agent
  end

  def find_vapi_agent
    # Try to find by agent ID first (most reliable for both phone and web calls)
    agent = VapiAgent.find_by(vapi_agent_id: agent_id) if agent_id.present?

    # Fallback to finding by phone number if available (for phone calls)
    if agent.nil? && phone_number.present?
      agent = VapiAgent.joins(:inbox)
                       .where(phone_number: phone_number)
                       .first
    end

    Rails.logger.warn "Could not find VapiAgent for agent_id: #{agent_id}, phone: #{phone_number}" if agent.nil?

    agent
  end

  def inbox
    @inbox ||= vapi_agent.inbox
  end

  def contact
    @contact ||= find_or_create_contact
  end

  def find_or_create_contact
    # Use phone number if available, otherwise use call_id for web calls
    source_identifier = phone_number.presence || "vapi_call_#{call_id}"

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: source_identifier,
      inbox: inbox,
      contact_attributes: {
        name: phone_number.present? ? formatted_phone_number : "Web Caller (#{call_id[0..7]})",
        phone_number: phone_number,
        additional_attributes: {
          source: 'vapi_call',
          vapi_call_id: call_id
        }
      }
    ).perform

    contact_inbox.contact
  end

  def conversation
    @conversation ||= find_or_create_conversation
  end

  def find_or_create_conversation
    contact_inbox = contact.contact_inboxes.find_by(inbox: inbox)
    return nil unless contact_inbox

    # Find existing conversation based on inbox settings
    existing_conversation = if inbox.lock_to_single_conversation
                              contact_inbox.conversations.last
                            else
                              contact_inbox.conversations.where.not(status: :resolved).last
                            end

    return existing_conversation if existing_conversation

    # Create new conversation
    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: {
        source: 'vapi_call',
        call_id: call_id
      }
    )
  end

  def call_id
    params.dig(:message, :call, :id) ||
      params.dig(:call, :id) ||
      params[:callId] ||
      params[:id]
  end

  def agent_id
    params.dig(:message, :call, :assistantId) ||
      params.dig(:call, :assistantId) ||
      params[:assistantId] ||
      params.dig(:assistant, :id)
  end

  def phone_number
    params.dig(:message, :call, :customer, :number) ||
      params.dig(:call, :customer, :number) ||
      params.dig(:customer, :number) ||
      params[:phoneNumber]
  end

  def formatted_phone_number
    return phone_number if phone_number.blank?

    begin
      TelephoneNumber.parse(phone_number).international_number
    rescue StandardError
      phone_number
    end
  end

  def duration
    # From end-of-call-report
    params.dig(:message, :call, :endedReason, :duration) ||
      params.dig(:call, :duration) ||
      params[:duration] ||
      params.dig(:endedReason, :duration)
  end

  def recording_url
    # From end-of-call-report
    params.dig(:message, :recordingUrl) ||
      params.dig(:call, :recordingUrl) ||
      params[:recordingUrl] ||
      params.dig(:recording, :url)
  end

  def format_duration(seconds)
    return "#{seconds}s" if seconds < 60

    minutes = seconds / 60
    remaining_seconds = seconds % 60

    if remaining_seconds.positive?
      "#{minutes}m #{remaining_seconds}s"
    else
      "#{minutes}m"
    end
  end
end

