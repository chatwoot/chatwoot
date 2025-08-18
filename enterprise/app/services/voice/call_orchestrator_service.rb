module Voice
  class CallOrchestratorService
    pattr_initialize [:account!, :inbox!, :direction!, :phone_number, :contact, :user, :call_sid]

    def inbound!
      raise 'From number is required' if phone_number.blank?

      @conversation = Voice::ConversationFinderService.new(
        account: account,
        phone_number: phone_number,
        is_outbound: false,
        inbox: inbox,
        call_sid: call_sid
      ).perform

      ensure_conference_sid!

      Voice::CallMessageBuilder.new(
        conversation: @conversation,
        direction: 'inbound',
        call_sid: call_sid,
        conference_sid: @conference_sid,
        from_number: phone_number,
        to_number: inbox.channel&.phone_number || '',
        user: nil
      ).perform


      @conversation
    end

    def outbound!
      raise 'Contact is required' if contact.blank?
      raise 'User is required' if user.blank?

      @conversation = Voice::ConversationFinderService.new(
        account: account,
        phone_number: contact.phone_number,
        is_outbound: true,
        inbox: inbox,
        call_sid: nil
      ).perform

      ensure_conference_sid!

      call_details = inbox.channel.initiate_call(
        to: contact.phone_number,
        conference_sid: @conference_sid,
        agent_id: user.id
      )

      updated_attributes = @conversation.additional_attributes.merge({
        'call_sid' => call_details[:call_sid],
        'requires_agent_join' => true,
        'agent_id' => user.id,
        'conference_sid' => @conference_sid,
        'call_direction' => 'outbound'
      })
      @conversation.update!(additional_attributes: updated_attributes)

      Voice::CallMessageBuilder.new(
        conversation: @conversation,
        direction: 'outbound',
        call_sid: call_details[:call_sid],
        conference_sid: @conference_sid,
        from_number: inbox.channel&.phone_number || '',
        to_number: contact.phone_number,
        user: user
      ).perform

      @conversation.update(last_activity_at: Time.current)


      [@conversation, call_details]
    end

    private

    def ensure_conference_sid!
      @conversation.reload
      @conference_sid = @conversation.additional_attributes['conference_sid']
      return if @conference_sid.present? && @conference_sid.match?(/^conf_account_\d+_conv_\d+$/)

      @conference_sid = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
      @conversation.additional_attributes['conference_sid'] = @conference_sid
      @conversation.save!
    end
  end
end
