module Voice
  class OutgoingCallService
    pattr_initialize [:account!, :contact!, :user!, { inbox_id: nil }]

    def process
      find_voice_inbox

      ActiveRecord::Base.transaction do
        orchestrator = Voice::CallOrchestratorService.new(
          account: account,
          inbox: @voice_inbox,
          direction: :outbound,
          contact: contact,
          user: user
        )

        @conversation, @call_details = orchestrator.outbound!
      end

      @conversation
    end

    private

    def find_voice_inbox
      scope = account.inboxes.where(channel_type: 'Channel::Voice')
      @voice_inbox = if inbox_id.present?
                       scope.find_by(id: inbox_id)
                     else
                       scope.first
                     end
      raise 'No Voice channel found' if @voice_inbox.blank?
      raise 'Contact has no phone number' if contact.phone_number.blank?
    end

  end
end
