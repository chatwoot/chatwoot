module Voice
  class CallMessageBuilder
    pattr_initialize [:conversation!, :direction!, :call_sid!, :conference_sid!, :from_number!, :to_number!, :user]

    def perform

      message_params = {
        content: 'Voice Call',
        message_type: direction == 'inbound' ? 'incoming' : 'outgoing',
        content_type: 'voice_call',
        content_attributes: {
          data: {
            call_sid: call_sid,
            status: 'ringing',
            conversation_id: conversation.display_id,
            call_direction: direction,
            conference_sid: conference_sid,
            from_number: from_number,
            to_number: to_number,
            meta: {
              created_at: Time.now.to_i,
              ringing_at: Time.now.to_i
            }
          }
        }
      }

      Messages::MessageBuilder.new(
        direction == 'outgoing' ? user : nil,
        conversation,
        message_params
      ).perform
    end
  end
end
