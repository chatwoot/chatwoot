module Voice
  class CallOrchestratorService
    pattr_initialize [:account!, :inbox!, :direction!, :phone_number, :contact, :user, :call_sid]

    def inbound!
      raise 'From number is required' if phone_number.blank?
      Rails.logger.info(
        "VOICE_ORCH_INBOUND account=#{account.id} inbox=#{inbox.id} from=#{phone_number} call_sid=#{call_sid}"
      )

      @conversation = Voice::ConversationFinderService.new(
        account: account,
        phone_number: phone_number,
        is_outbound: false,
        inbox: inbox,
        call_sid: call_sid
      ).perform

      if call_sid.present? && @conversation.identifier != call_sid
        @conversation.update!(identifier: call_sid)
      end

      ensure_conference_sid!(call_sid)

      Voice::CallMessageBuilder.new(
        conversation: @conversation,
        direction: 'inbound',
        call_sid: call_sid,
        conference_sid: @conference_sid,
        from_number: phone_number,
        to_number: inbox.channel&.phone_number || '',
        user: nil
      ).perform


      Rails.logger.info(
        "VOICE_ORCH_INBOUND_OK account=#{account.id} conv=#{@conversation.display_id} conf=#{@conference_sid}"
      )
      @conversation
    end

  def outbound!
    raise 'Contact is required' if contact.blank?
    raise 'User is required' if user.blank?
    Rails.logger.info(
      "VOICE_ORCH_OUTBOUND account=#{account.id} inbox=#{inbox.id} to=#{contact&.phone_number} user=#{user.id}"
    )

      # Initiate call to fetch call_sid from provider
      call_details = inbox.channel.initiate_call(
        to: contact.phone_number,
        conference_sid: nil,
        agent_id: user.id
      )

      # Build conversation and first message via OutboundCallBuilder
      @conversation = Voice::OutboundCallBuilder.new(
        account: account,
        inbox: inbox,
        user: user,
        contact: contact,
        call_sid: call_details[:call_sid],
        to_number: contact.phone_number
      ).perform

      @conversation.update(last_activity_at: Time.current)
      conf_sid = @conversation.additional_attributes['conference_sid']
      Rails.logger.info(
        "VOICE_ORCH_OUTBOUND_OK account=#{account.id} conv=#{@conversation.display_id} call_sid=#{call_details[:call_sid]} conf=#{conf_sid}"
      )

      {
        conversation_id: @conversation.display_id,
        call_sid: call_details[:call_sid],
        conference_sid: conf_sid
      }
    end

    private

    def ensure_conference_sid!(_explicit_call_sid = nil)
      @conversation.reload
      @conference_sid = @conversation.additional_attributes['conference_sid']
      return if @conference_sid.present?

      @conference_sid = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
      @conversation.additional_attributes['conference_sid'] = @conference_sid
      @conversation.save!
    end
  end
end
