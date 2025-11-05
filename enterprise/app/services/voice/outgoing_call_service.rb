module Voice
  class OutgoingCallService
    pattr_initialize [:account!, :contact!, :user!, { inbox_id: nil }]

    def process
      find_voice_inbox

      ActiveRecord::Base.transaction do
        Voice::CallOrchestratorService.new(
          account: account,
          inbox: @voice_inbox,
          direction: :outbound,
          contact: contact,
          user: user
        ).outbound!
      end
    end

    private

    def find_voice_inbox
      scope = account.inboxes.where(channel_type: 'Channel::Voice')
      @voice_inbox = scope.find(inbox_id)
      raise 'Contact has no phone number' if contact.phone_number.blank?
    end
  end
end
