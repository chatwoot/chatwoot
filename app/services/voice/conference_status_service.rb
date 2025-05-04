module Voice
  class ConferenceStatusService
    pattr_initialize [:account!, :params!]

    def process
      # Log all incoming parameters for debugging
      Rails.logger.info("🎤 CONFERENCE STATUS PARAMS: #{params.to_unsafe_h.except('controller', 'action').to_json}")
      
      find_conversation
      queue_status_processing if @conversation
    end

    def status_info
      # Normalize the event name to match our expected format
      raw_event = params['StatusCallbackEvent']
      
      # Log the raw event to help with debugging
      Rails.logger.info("🎧 RAW EVENT RECEIVED: '#{raw_event}'")
      
      # Convert Twilio's event formats to our standardized kebab-case
      normalized_event = if raw_event.present?
                          # Clean up the string first - convert to lowercase and remove spaces
                          event_text = raw_event.downcase.gsub(/\s+/, '')
                          
                          # Handle all possible format variations from Twilio
                          case event_text
                          # Participant join events (camelCase, kebab-case, no dash)
                          when 'participant-join', 'participantjoin', 'participantjoined', 'participantjoin', 'participant_join'
                            'participant-join'
                          
                          # Participant leave events (camelCase, kebab-case, no dash)
                          when 'participant-leave', 'participantleave', 'participantleft', 'participantleave', 'participant_leave'
                            'participant-leave'
                          
                          # Conference start events (camelCase, kebab-case, no dash)
                          when 'conference-start', 'conferencestart', 'conferencestarted', 'conferencestart', 'conference_start'
                            'conference-start'
                          
                          # Conference end events (camelCase, kebab-case, no dash)
                          when 'conference-end', 'conferenceend', 'conferenceended', 'conferenceend', 'conference_end'
                            'conference-end'
                          
                          # Add other Twilio event variations if needed
                          
                          # For any other event, standardize to kebab-case
                          else
                            # Convert camelCase to kebab-case
                            kebab_case = event_text.gsub(/([a-z\d])([A-Z])/, '\1-\2').downcase
                            # Convert snake_case to kebab-case
                            kebab_case = kebab_case.gsub('_', '-')
                            # Remove any extra dashes
                            kebab_case = kebab_case.gsub(/--+/, '-')
                            kebab_case
                          end
                        else
                          # Default if no event is provided
                          'unknown'
                        end

      Rails.logger.info("🎧 NORMALIZED EVENT: '#{raw_event}' -> '#{normalized_event}'")
      
      {
        call_sid: params['CallSid'],
        conference_sid: params['ConferenceSid'],
        event: normalized_event,
        participant_sid: params['ParticipantSid'],
        participant_label: params['ParticipantLabel'],
        call_sid_ending_with: params['CallSidEndingWith'],
        audio_level: params['AudioLevel']
      }
    end

    private

    def find_conversation
      @conversation = nil

      # Try finding by conference_sid
      if status_info[:conference_sid].present?
        @conversation = account.conversations
                               .where("additional_attributes->>'conference_sid' = ?", status_info[:conference_sid])
                               .first
                               
        Rails.logger.info("🔍 SEARCHING BY CONFERENCE_SID: #{status_info[:conference_sid]}") if @conversation.nil?
      end

      # If not found and conference_sid looks like our format, extract conversation ID
      if @conversation.nil? && status_info[:conference_sid].present? && status_info[:conference_sid].start_with?('conf_account_')
        conference_parts = status_info[:conference_sid].match(/conf_account_\d+_conv_(\d+)/)
        if conference_parts && conference_parts[1].present?
          conversation_display_id = conference_parts[1]
          @conversation = account.conversations.find_by(display_id: conversation_display_id)
          Rails.logger.info("🎧 Found conversation by display_id=#{conversation_display_id} from conference_sid=#{status_info[:conference_sid]}")
        end
      end

      # If still not found, try by call_sid
      if @conversation.nil? && status_info[:call_sid].present?
        @conversation = account.conversations
                               .where("additional_attributes->>'call_sid' = ?", status_info[:call_sid])
                               .first
                               
        Rails.logger.info("🔍 SEARCHING BY CALL_SID: #{status_info[:call_sid]}") if @conversation.nil?
      end
      
      if @conversation
        Rails.logger.info("✅ FOUND CONVERSATION: id=#{@conversation.id} display_id=#{@conversation.display_id}")
      else
        Rails.logger.error("❌ CONVERSATION NOT FOUND for call_sid=#{status_info[:call_sid]} conference_sid=#{status_info[:conference_sid]}")
        return
      end

      # Update participant info if conversation found
      update_participant_info if @conversation
    end

    def update_participant_info
      # Initialize or get current participants list
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['participants'] ||= {}
      
      participant_sid = status_info[:participant_sid]
      return unless participant_sid.present?
      
      # Log the received event
      Rails.logger.info("👥 PARTICIPANT EVENT: #{status_info[:event]} for #{participant_sid} (#{status_info[:participant_label]})")
      
      # Update based on event type
      case status_info[:event]
      when 'participant-join'
        # Add participant
        @conversation.additional_attributes['participants'][participant_sid] = {
          'joined_at' => Time.now.to_i,
          'type' => status_info[:participant_label]&.start_with?('agent') ? 'agent' : 'caller',
          'call_sid' => status_info[:call_sid],
          'status' => 'joined'
        }
        
        # Flag outbound calls that need agent join if this is a caller
        if @conversation.additional_attributes['call_direction'] == 'outbound' && 
            status_info[:participant_label]&.start_with?('caller-')
          # This is the customer joining an outbound call - flag for agent to join immediately
          @conversation.additional_attributes['requires_agent_join'] = true
          # Broadcast an immediate "incoming call" notification for the agent
          broadcast_agent_join_notification
        end
      when 'participant-leave'
        # Only update if the participant is in the list
        if @conversation.additional_attributes['participants'].key?(participant_sid)
          @conversation.additional_attributes['participants'][participant_sid]['status'] = 'left'
          @conversation.additional_attributes['participants'][participant_sid]['left_at'] = Time.now.to_i
        end
      end
      
      # Save the updated conversation
      @conversation.save!
    end

    def broadcast_agent_join_notification
      # Get the contact, ensuring we still have one
      contact = @conversation.contact
      unless contact
        # If contact is missing, try to find or create one based on info available
        # This shouldn't normally happen but is a safeguard
        phone_numbers = @conversation.messages.where(content_type: 'voice_call')
                                    .map { |m| m.content_attributes.dig('data', 'to_number') }.compact.first
        
        if phone_numbers
          contact = account.contacts.find_or_create_by(phone_number: phone_numbers) do |c|
            c.name = "Contact from #{phone_numbers}"
          end
          # Update conversation with the new contact
          @conversation.update(contact_id: contact.id)
        else
          # If we can't find a phone number, create a generic contact
          contact = account.contacts.create!(phone_number: "unknown-#{Time.now.to_i}")
          @conversation.update(contact_id: contact.id)
        end
      end

      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: {
            call_sid: status_info[:call_sid],
            conversation_id: @conversation.id,
            inbox_id: @conversation.inbox_id,
            inbox_name: @conversation.inbox.name,
            contact_name: contact.name || 'Outbound Call',
            contact_id: contact.id,
            is_outbound: true,
            account_id: account.id,
            conference_sid: status_info[:conference_sid]
          }
        }
      )
      
      Rails.logger.info("📣 BROADCAST: Sent agent join notification")
    end

    def queue_status_processing
      # Process the status update directly using the service
      Rails.logger.info("📊 PROCESSING CONFERENCE EVENT: #{status_info[:event]}")
      
      Voice::ConferenceStatusUpdateService.new(
        conversation: @conversation,
        event: status_info[:event],
        call_sid: status_info[:call_sid],
        conference_sid: status_info[:conference_sid],
        participant_sid: status_info[:participant_sid],
        participant_label: status_info[:participant_label]
      ).process
    end
  end
end