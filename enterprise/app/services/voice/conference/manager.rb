module Voice
  module Conference
    class Manager
      pattr_initialize [:conversation!, :event!, :call_sid!, :participant_label]

      EVENT_HANDLERS = {
        'start' => :handle_start,
        'end' => :handle_end,
        'join' => :handle_join,
        'leave' => :handle_leave
      }.freeze

      END_STATUS = {
        'in-progress' => 'completed',
        'ringing' => 'no-answer'
      }.freeze

      def process
        handler = EVENT_HANDLERS[event]
        return unless handler

        send(handler)
      end

      private

      def call_status_manager
        @call_status_manager ||= Voice::CallStatus::Manager.new(
          conversation: conversation,
          call_sid: call_sid,
          provider: :twilio
        )
      end

      def handle_start
        return if %w[in-progress completed].include?(current_status)

        call_status_manager.process_status_update('ringing')
      end

      def handle_end
        target_status = END_STATUS[current_status] || 'completed'
        call_status_manager.process_status_update(target_status)
      end

      def handle_join
        return unless mark_in_progress?

        call_status_manager.process_status_update('in-progress')
      end

      def handle_leave
        return unless %w[in-progress ringing].include?(current_status)

        next_status = current_status == 'ringing' ? 'no-answer' : 'completed'
        call_status_manager.process_status_update(next_status)

        return if conversation.additional_attributes['call_ended_at'].present?

        Voice::Conference::EndService.new(conversation: conversation).perform
      end

      def current_status
        conversation.additional_attributes['call_status']
      end

      def mark_in_progress?
        conversation.additional_attributes['call_ended_at'].blank? &&
          current_status == 'ringing' &&
          participant_label.to_s.start_with?('agent')
      end
    end
  end
end
