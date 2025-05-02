class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  require 'securerandom'
  before_action :fetch_contact

  def create
    # Find a Voice channel
    voice_inbox = Current.account.inboxes.find_by(channel_type: 'Channel::Voice')
    
    if voice_inbox.blank?
      render json: { error: 'No Voice channel found' }, status: :unprocessable_entity
      return
    end

    if @contact.phone_number.blank?
      render json: { error: 'Contact has no phone number' }, status: :unprocessable_entity
      return
    end

    begin
      # Create a new conversation for this call
      conversation = find_or_create_conversation(voice_inbox)
      
      # CRITICAL: Create a conference name FIRST to ensure consistency
      conference_name = "conf_account_#{Current.account.id}_conv_#{conversation.display_id}"
      
      # Create conference for outbound call
      
      # Initiate the call using the channel's implementation - this returns the call details
      call_details = voice_inbox.channel.initiate_call(
        to: @contact.phone_number, 
        conference_name: conference_name
      )
      
      # Add the conference name to the call details
      call_details[:conference_sid] = conference_name
      
      # Create a message for this call with call details
      params = {
        content: "Outgoing voice call initiated to #{@contact.phone_number}",
        message_type: :activity,
        additional_attributes: call_details,
        source_id: call_details[:call_sid] # Use call SID as source_id
      }
      
      message = Messages::MessageBuilder.new(Current.user, conversation, params).perform
      
      # Make sure the conversation has the latest activity timestamp
      conversation.update(last_activity_at: Time.current)
      
      # Add the conference_sid to the conversation's additional_attributes
      # Ensure we don't lose other attributes that might already be set
      updated_attributes = (conversation.additional_attributes || {}).merge(call_details)
      
      # CRITICAL: Add additional attributes needed for immediate agent join notification
      updated_attributes[:call_status] = 'in-progress'
      updated_attributes[:requires_agent_join] = true
      
      # Now update the conversation with all the attributes
      conversation.update!(additional_attributes: updated_attributes)
      
      # Conference created successfully
      
      # DIRECT AGENT NOTIFICATION: Immediately broadcast to ActionCable that agent needs to join
      # This bypasses any queueing and directly tells the frontend a call needs agent
      ActionCable.server.broadcast(
        "account_#{Current.account.id}",
        {
          event: 'incoming_call',
          data: {
            call_sid: call_details[:call_sid],
            conversation_id: conversation.id,
            inbox_id: voice_inbox.id,
            inbox_name: voice_inbox.name,
            contact_name: @contact.name || @contact.phone_number,
            contact_id: @contact.id,
            account_id: Current.account.id,
            is_outbound: true,
            conference_sid: conference_name,
            requires_agent_join: true,
            # Send additional information to help with debugging
            call_direction: 'outbound'
          }
        }
      )
      
      # Broadcast the conversation and message to the appropriate ActionCable channels
      ActionCableBroadcastJob.perform_later(
        conversation.account_id,
        'conversation.created',
        conversation.push_event_data.merge(
          message: message.push_event_data,
          status: 'open'
        )
      )
      
      render json: conversation
    rescue StandardError => e
      Rails.logger.error("Error initiating call: #{e.message}")
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def fetch_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def find_or_create_conversation(inbox)
    conversation = inbox.conversations.where(contact_id: @contact.id).last

    if conversation.nil? || !conversation.open?
      # Find or create a contact_inbox for this contact and inbox
      contact_inbox = ContactInbox.find_or_initialize_by(
        contact_id: @contact.id,
        inbox_id: inbox.id
      )
      
      # Set the source_id if it's a new record
      if contact_inbox.new_record?
        # For voice channels, use the phone number as the source_id
        contact_inbox.source_id = @contact.phone_number
      end
      
      contact_inbox.save!
      
      conversation = ::Conversation.create!(
        account_id: Current.account.id,
        inbox_id: inbox.id,
        contact_id: @contact.id,
        contact_inbox_id: contact_inbox.id,
        status: :open
      )

      # Add a note about the call being initiated
      params = {
        message_type: :activity,
        content: "Voice call initiated to #{@contact.phone_number}",
        source_id: "voice_call_#{SecureRandom.uuid}" # Generate a unique source_id
      }
      
      Messages::MessageBuilder.new(Current.user, conversation, params).perform
    end

    conversation
  end
end