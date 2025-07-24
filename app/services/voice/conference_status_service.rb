module Voice
  class ConferenceStatusService
    pattr_initialize [:account!, :params!]

    def process
      info = status_info
      conversation = find_conversation(info)

      return unless conversation


      Voice::ConferenceManagerService.new(
        conversation: conversation,
        event: info[:event],
        call_sid: info[:call_sid],
        participant_label: info[:participant_label]
      ).process
    end

    def status_info
      {
        call_sid: params['CallSid'],
        conference_sid: params['ConferenceSid'],
        event: params['StatusCallbackEvent'],
        participant_sid: params['ParticipantSid'],
        participant_label: params['ParticipantLabel']
      }
    end

    private


    def find_conversation(info)
      # Try by conference_sid first
      if info[:conference_sid].present?
        conversation = account.conversations.where("additional_attributes->>'conference_sid' = ?", info[:conference_sid]).first
        return conversation if conversation

        # Try pattern matching for our format
        if info[:conference_sid].start_with?('conf_account_')
          match = info[:conference_sid].match(/conf_account_\d+_conv_(\d+)/)
          return account.conversations.find_by(display_id: match[1]) if match && match[1].present?
        end
      end

      # Try by call_sid
      if info[:call_sid].present?
        finder_service = Voice::ConversationFinderService.new(
          account: account,
          call_sid: info[:call_sid]
        )
        return finder_service.find_by_call_sid
      end

      nil
    end

  end
end
