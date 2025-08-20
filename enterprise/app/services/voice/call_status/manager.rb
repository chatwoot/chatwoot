module Voice
  module CallStatus
    class Manager
      pattr_initialize [:conversation!, :call_sid, :provider]

      # Use Twilio-native statuses end-to-end
      # Common values: queued, initiated, ringing, in-progress, completed, busy, failed, no-answer, canceled
      VALID_STATUSES = %w[queued initiated ringing in-progress completed busy failed no-answer canceled].freeze
      TERMINAL_STATUSES = %w[completed busy failed no-answer canceled].freeze

      def process_status_update(status, duration = nil, is_first_response = false, custom_message = nil)
        normalized_status = status
        prev_status = conversation.additional_attributes&.dig('call_status')

        return true if !is_first_response && prev_status == normalized_status

        if duration.nil? && call_ended?(normalized_status) && conversation.additional_attributes['call_started_at']
          duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
        end

        update_status(normalized_status, duration)

        if custom_message.present?
          create_activity_message(custom_message)
        elsif call_ended?(normalized_status)
          create_activity_message(activity_message_for_status(normalized_status))
        end

        true
      end


      def is_outbound?
        direction = conversation.additional_attributes['call_direction']
        return direction == 'outbound' if direction.present?

        conversation.additional_attributes['requires_agent_join'] == true
      end


      def call_ended?(status)
        TERMINAL_STATUSES.include?(status)
      end

      def create_activity_message(content, additional_attributes = {})
        return nil if content.blank?

        conversation.messages.create!(
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          content: content,
          sender: nil,
          additional_attributes: additional_attributes
        )
      end

      private

      def update_status(status, duration)
        conversation.additional_attributes ||= {}
        conversation.additional_attributes['call_status'] = status

        if status == 'in-progress'
          conversation.additional_attributes['call_started_at'] ||= Time.now.to_i
        elsif call_ended?(status)
          conversation.additional_attributes['call_ended_at'] = Time.now.to_i
          conversation.additional_attributes['call_duration'] = duration if duration
        end

        # Save both additional_attributes changes and last_activity_at
        conversation.update!(
          additional_attributes: conversation.additional_attributes,
          last_activity_at: Time.current
        )
        update_message_status(status, duration)
      end

      def update_message_status(status, duration)
        message = find_voice_call_message
        return unless message

        content_attributes = message.content_attributes || {}
        content_attributes['data'] ||= {}
        content_attributes['data']['status'] = status
        content_attributes['data']['duration'] = duration if duration

        message.update!(content_attributes: content_attributes)
      end

      def find_voice_call_message
        conversation.messages
                    .where(content_type: 'voice_call')
                    .order(created_at: :desc)
                    .first
      end

      def activity_message_for_status(status)
        return 'Call ended' if status == 'completed' || status == 'canceled'
        return 'No answer' if status == 'no-answer'
        return 'Call ended' if %w[busy failed].include?(status)

        'Call ended'
      end
    end
  end
end
