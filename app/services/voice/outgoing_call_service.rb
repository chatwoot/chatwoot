module Voice
  class OutgoingCallService
    pattr_initialize [:account!, :contact!, :user!]

    def process
      find_voice_inbox
      create_conversation
      initiate_call
      create_conversation_messages
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
      # Find or create contact inbox
      contact_inbox = ContactInbox.find_or_initialize_by(
        contact_id: contact.id,
        inbox_id: @voice_inbox.id
      )
      
      # Set phone number as source_id if new
      if contact_inbox.new_record?
        contact_inbox.source_id = contact.phone_number
      end
      
      contact_inbox.save!
      
      # Create a new conversation with call details
      @conversation = account.conversations.create!(
        account_id: account.id,
        inbox_id: @voice_inbox.id,
        contact_id: contact.id,
        contact_inbox_id: contact_inbox.id,
        status: :open,
        additional_attributes: {
          'call_initiated_at' => Time.now.to_i,
          'call_type' => 'outbound',
          'call_direction' => 'outbound'
        }
      )

      # Create conference name for outbound call
      @conference_name = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
    end

    def initiate_call
      # Initiate the call using the channel's implementation
      @call_details = @voice_inbox.channel.initiate_call(
        to: contact.phone_number, 
        conference_name: @conference_name,
        agent_id: user.id # Pass the agent ID to track who initiated the call
      )
      
      # Add conference details to the conversation
      @call_details[:conference_sid] = @conference_name
      
      # Update conversation with call details
      updated_attributes = (@conversation.additional_attributes || {}).merge(@call_details)
      updated_attributes[:call_status] = 'in-progress'
      updated_attributes[:requires_agent_join] = true
      updated_attributes[:agent_id] = user.id # Store the agent ID who initiated the call
      @conversation.update!(additional_attributes: updated_attributes)
    end

    def create_conversation_messages
      # Create a single outgoing message from agent for this call
      @widget_message = Messages::MessageBuilder.new(
        user, # For outgoing calls, sender is the agent
        @conversation,
        {
          content: 'Voice Call',
          message_type: :outgoing, # Make sure this is 'outgoing' to be sent from the agent
          content_type: 'voice_call', # Direct content type for voice calls
          content_attributes: {
            data: {
              call_sid: @call_details[:call_sid],
              status: 'ringing',
              conversation_id: @conversation.id,
              call_direction: 'outbound',
              meta: {
                created_at: Time.now.to_i
              }
            }
          },
          sender: user
        }
      ).perform
      
      # Create a simple activity message (no sender needed)
      Messages::MessageBuilder.new(
        nil, # Activity messages don't need a sender
        @conversation,
        {
          content: "Outgoing call to #{contact.name || contact.phone_number}",
          message_type: :activity,
          additional_attributes: @call_details
        }
      ).perform
      
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