module Voice
  class OutgoingCallService
    pattr_initialize [:account!, :contact!, :user!]

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
      @voice_inbox = account.inboxes.find_by(channel_type: 'Channel::Voice')
      raise 'No Voice channel found' if @voice_inbox.blank?
      raise 'Contact has no phone number' if contact.phone_number.blank?
      
    end

  end
end
