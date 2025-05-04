module Voice
  class TwilioCallStatusService
    pattr_initialize [:conversation!, :call_sid!, :call_status!, :is_outbound, :duration]

    CALL_STATUS_MESSAGES = {
      'initiated' => { outbound: 'Outbound call initiated', inbound: 'Initiating call' },
      'ringing' => { outbound: 'Phone ringing', inbound: 'Phone ringing' },
      'in-progress' => { 
        outbound: { first: 'Call connected', next: 'Call in progress' },
        inbound: { first: 'Call answered', next: 'Call in progress' }
      },
      'completed' => { outbound: 'Call completed', inbound: 'Call completed' },
      'busy' => { outbound: 'Call busy', inbound: 'Call busy' },
      'failed' => { outbound: 'Call failed', inbound: 'Call failed' },
      'no-answer' => { outbound: 'Call not answered', inbound: 'Call not answered' },
      'canceled' => { outbound: 'Call canceled', inbound: 'Call canceled' }
    }.freeze

    def process(is_first_response = false)
      # Skip if no changes needed
      prev_status = conversation.additional_attributes&.dig('call_status')
      return if !is_first_response && prev_status == call_status

      # Update conversation status using shared service
      message_service.update_call_status(call_status, duration)

      # Create activity message
      create_activity_message(is_first_response)

      # Update voice call message
      message_service.update_voice_call_status(call_status, duration)
    end

    private

    def message_service
      @message_service ||= Voice::MessageUpdateService.new(
        conversation: conversation,
        call_sid: call_sid
      )
    end

    def create_activity_message(is_first_response)
      activity_message = activity_message_for_status(is_first_response)
      message_service.create_activity_message(activity_message)
    end

    def activity_message_for_status(is_first_response)
      call_direction = is_outbound ? :outbound : :inbound
      
      if call_status == 'in-progress'
        message_type = is_first_response ? :first : :next
        return CALL_STATUS_MESSAGES[call_status][call_direction][message_type]
      elsif CALL_STATUS_MESSAGES.key?(call_status)
        return CALL_STATUS_MESSAGES[call_status][call_direction]
      else
        return "Call status: #{call_status}"
      end
    end
  end
end