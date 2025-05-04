module Voice
  class OutgoingCallService
    pattr_initialize [:account!, :contact!, :user!]

    def process
      find_voice_inbox
      create_conversation
      initiate_call
      create_voice_call_message
      broadcast_to_agent
      @conversation
    end

    private

    def find_voice_inbox
      @voice_inbox = account.inboxes.find_by(channel_type: 'Channel::Voice')
      raise "No Voice channel found" if @voice_inbox.blank?
      raise "Contact has no phone number" if contact.phone_number.blank?
    end

    def create_conversation
      # Use the ConversationFinderService to create the conversation
      @conversation = Voice::ConversationFinderService.new(
        account: account,
        phone_number: contact.phone_number,
        is_outbound: true,
        inbox: @voice_inbox,
        call_sid: nil # This will be set after call is initiated
      ).perform
      
      # Create conference name for outbound call
      @conference_name = @conversation.additional_attributes['conference_sid']
    end

    def initiate_call
      # Initiate the call using the channel's implementation
      @call_details = @voice_inbox.channel.initiate_call(
        to: contact.phone_number, 
        conference_name: @conference_name,
        agent_id: user.id # Pass the agent ID to track who initiated the call
      )
      
      # Update conversation with call details
      updated_attributes = @conversation.additional_attributes.merge({
        'call_sid' => @call_details[:call_sid],
        'call_status' => 'in-progress',
        'requires_agent_join' => true,
        'agent_id' => user.id # Store the agent ID who initiated the call
      })
      
      @conversation.update!(additional_attributes: updated_attributes)
    end

    def create_voice_call_message
      # Create a voice call message
      message_params = {
        content: 'Voice Call',
        message_type: 'outgoing',
        content_type: 'voice_call',
        content_attributes: {
          data: {
            call_sid: @call_details[:call_sid],
            status: 'ringing',
            conversation_id: @conversation.id,
            call_direction: 'outbound',
            conference_sid: @conference_name,
            from_number: @voice_inbox.channel.phone_number,
            to_number: contact.phone_number,
            agent_id: user.id,
            meta: {
              created_at: Time.now.to_i,
              ringing_at: Time.now.to_i
            }
          }
        }
      }
      
      # Create the message
      @widget_message = Messages::MessageBuilder.new(
        user,
        @conversation,
        message_params
      ).perform
      
      # Create an activity message for the outgoing call
      message_service = Voice::MessageUpdateService.new(
        conversation: @conversation,
        call_sid: @call_details[:call_sid]
      )
      
      message_service.create_activity_message("Outgoing call to #{contact.name || contact.phone_number}")
      
      # Update last activity timestamp
      @conversation.update(last_activity_at: Time.current)
    end

    def broadcast_to_agent
      # Direct notification that agent needs to join
      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: {
            call_sid: @call_details[:call_sid],
            conversation_id: @conversation.id,
            inbox_id: @voice_inbox.id,
            inbox_name: @voice_inbox.name,
            contact_name: contact.name || contact.phone_number,
            contact_id: contact.id,
            account_id: account.id,
            is_outbound: true,
            conference_sid: @conference_name,
            requires_agent_join: true,
            call_direction: 'outbound'
          }
        }
      )
      
      # Broadcast the conversation and message
      ActionCableBroadcastJob.perform_later(
        @conversation.account_id,
        'conversation.created',
        @conversation.push_event_data.merge(
          message: @widget_message.push_event_data,
          status: 'open'
        )
      )
    end
  end
end