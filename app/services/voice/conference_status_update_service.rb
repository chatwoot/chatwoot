module Voice
  class ConferenceStatusUpdateService
    pattr_initialize [:conversation!, :event!, :call_sid!, :conference_sid, :participant_sid, :participant_label]

    def process
      update_conversation
      create_activity_message
      # We no longer need to explicitly broadcast call status
      # since the Message model's after_update_commit hook will broadcast updates
    end

    private

    def update_conversation
      # No need to track status changes for broadcasting anymore
      
      # Find the message to update
      message = find_call_message

      case event
      when 'conference-start'
        conversation.additional_attributes['conference_status'] = 'started'
        update_call_message_widget(message, 'ringing') if message
      when 'conference-end'
        conversation.additional_attributes['conference_status'] = 'ended'
        conversation.additional_attributes['call_status'] = 'completed'
        conversation.additional_attributes['call_ended_at'] = Time.now.to_i
        conversation.status = :resolved
        
        # Calculate call duration if possible
        if conversation.additional_attributes['call_started_at']
          call_duration = Time.now.to_i - conversation.additional_attributes['call_started_at']
          update_call_message_widget(message, 'ended', call_duration) if message
        else
          update_call_message_widget(message, 'ended') if message
        end
      when 'participant-join'
        update_participant_info('joined')
        
        # Is this participant an agent?
        is_agent = participant_label&.start_with?('agent')
        
        # If this is an agent joining, update the call status
        if is_agent && conversation.additional_attributes['call_status'] == 'ringing'
          conversation.additional_attributes['call_status'] = 'active'
          conversation.additional_attributes['call_started_at'] = Time.now.to_i
          update_call_message_widget(message, 'active') if message
        end
      when 'participant-leave'
        update_participant_info('left')
        
        # Was this participant the caller?
        is_caller = participant_label&.start_with?('caller')
        
        # If this is the caller leaving and call is still ringing (no agent joined), mark as missed
        if is_caller && conversation.additional_attributes['call_status'] == 'ringing'
          has_agent_joined = conversation.additional_attributes['participants']&.values&.any? do |p| 
            p['type'] == 'agent' && p['status'] == 'joined'
          end
          
          unless has_agent_joined
            conversation.additional_attributes['call_status'] = 'missed'
            update_call_message_widget(message, 'missed') if message
          end
        end
      end
      
      # Save the updated conversation
      conversation.save!
    end

    def create_activity_message
      # Determine the message content based on the event
      content = case event
                when 'conference-start'
                  'Conference started'
                when 'conference-end'
                  'Conference ended'
                when 'participant-join'
                  participant_type = participant_label&.start_with?('agent') ? 'Agent' : 'Caller'
                  "#{participant_type} joined the call"
                when 'participant-leave'
                  participant_type = participant_label&.start_with?('agent') ? 'Agent' : 'Caller'
                  "#{participant_type} left the call"
                else
                  "Call event: #{event}"
                end
      
      # Create an activity message
      Messages::MessageBuilder.new(
        nil,
        conversation,
        {
          content: content,
          message_type: :activity,
          additional_attributes: {
            call_sid: call_sid,
            event_type: event,
            conference_sid: conference_sid,
            timestamp: Time.now.to_i,
            participant_sid: participant_sid
          }
        }
      ).perform
    end

    def update_participant_info(status)
      # Initialize participants tracking if not already present
      conversation.additional_attributes['participants'] ||= {}
      
      # Update participant info
      if status == 'joined'
        conversation.additional_attributes['participants'][participant_sid] = {
          joined_at: Time.now.to_i,
          type: participant_label&.start_with?('agent') ? 'agent' : 'caller',
          call_sid: call_sid,
          status: 'joined'
        }
      elsif status == 'left'
        # Only update if the participant is in the list
        if conversation.additional_attributes['participants'].key?(participant_sid)
          conversation.additional_attributes['participants'][participant_sid]['status'] = 'left'
          conversation.additional_attributes['participants'][participant_sid]['left_at'] = Time.now.to_i
        end
      end
    end

    # We no longer need a separate broadcasting method
    # The Message model's after_update_commit hook will handle broadcasting updates

    # This method is no longer needed as we update the call widget directly in the update_conversation method
    # It was keeping for backward compatibility in case any old calls were processed with this method

    def find_call_message
      conversation.messages
                  .where(content_type: 'voice_call')
                  .where("content_attributes->'data'->>'call_sid' = ?", call_sid)
                  .first
    end

    def update_call_message_widget(message, status, duration = nil)
      return unless message
      
      # Update the message's content attributes
      content_attributes = message.content_attributes || {}
      message_data = content_attributes['data'] || {}
      
      # Update status and add duration if provided
      message_data['status'] = status
      message_data['duration'] = duration if duration
      message_data['meta'] ||= {}
      message_data['meta']["#{status}_at"] = Time.now.to_i
      
      content_attributes['data'] = message_data
      message.content_attributes = content_attributes
      message.save!
    end

  end
end