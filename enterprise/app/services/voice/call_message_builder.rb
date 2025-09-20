module Voice
  class CallMessageBuilder
    pattr_initialize [:conversation!, :direction!, :call_sid!, :conference_sid!, :from_number!, :to_number!, :user]

    def perform
      timestamp = Time.current.to_i
      existing_message = find_existing_message
      return update_existing_message(existing_message, timestamp) if existing_message

      Messages::MessageBuilder.new(
        direction == 'outgoing' ? user : nil,
        conversation,
        build_message_params(timestamp)
      ).perform
    end

    private

    def find_existing_message
      conversation.messages.voice_calls.first
    end

    def update_existing_message(message, timestamp)
      attrs = (message.content_attributes || {}).deep_dup
      attrs['data'] ||= {}
      merge_payload!(attrs['data'], timestamp)

      message.update!(
        message_type: direction == 'inbound' ? :incoming : :outgoing,
        content_attributes: attrs
      )

      message
    end

    def build_message_params(timestamp)
      {
        content: 'Voice Call',
        message_type: direction == 'inbound' ? :incoming : :outgoing,
        content_type: 'voice_call',
        content_attributes: { data: build_payload(timestamp) }
      }
    end

    def build_payload(timestamp)
      payload = {}
      merge_payload!(payload, timestamp)
      payload
    end

    def merge_payload!(data, timestamp)
      data['call_sid'] = call_sid
      data['status'] ||= 'ringing'
      data['conversation_id'] = conversation.display_id
      data['call_direction'] = direction
      data['conference_sid'] = conference_sid
      data['from_number'] = from_number
      data['to_number'] = to_number
      data['meta'] ||= {}
      data['meta']['created_at'] ||= timestamp
      data['meta']['ringing_at'] ||= timestamp
    end
  end
end
