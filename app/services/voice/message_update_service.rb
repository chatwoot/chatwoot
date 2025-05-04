module Voice
  class MessageUpdateService
    pattr_initialize [:conversation!, :call_sid]

    def update_voice_call_status(status, duration = nil)
      message = find_voice_call_message
      return unless message

      # Log message found for debugging
      Rails.logger.info("📱 UPDATE VOICE CALL STATUS: Found message: #{message.id}, updating status: #{status}")

      # Get current content attributes, initialize if needed
      content_attributes = message.content_attributes || {}
      content_attributes['data'] ||= {}

      # Log previous status
      previous_status = content_attributes['data']['status']
      Rails.logger.info("📱 PREVIOUS STATUS: #{previous_status} -> NEW STATUS: #{status}")

      # Update fields
      content_attributes['data']['status'] = status
      content_attributes['data']['duration'] = duration if duration
      content_attributes['data']['meta'] ||= {}
      content_attributes['data']['meta']["#{status}_at"] = Time.now.to_i
      content_attributes['data']['updated_at'] = Time.now.to_i

      # Add a flag to force the UI to refresh
      content_attributes['data']['status_updated'] = Time.now.to_i

      # Save the message with a rescue to ensure we get error details if it fails
      begin
        result = message.update(content_attributes: content_attributes)
        if result
          Rails.logger.info("✅ VOICE CALL STATUS UPDATED: Message #{message.id} status: #{status}")
        else
          Rails.logger.error("❌ VOICE CALL STATUS UPDATE FAILED: #{message.errors.full_messages.join(', ')}")
        end
      rescue StandardError => e
        Rails.logger.error("❌ VOICE CALL STATUS UPDATE ERROR: #{e.message}")
        Rails.logger.error("❌ BACKTRACE: #{e.backtrace[0..3].join("\n")}")
      end

      message
    end

    def find_voice_call_message
      # First try to find by call_sid
      message = nil

      if call_sid.present?
        # Try to find by exact call_sid match
        Rails.logger.info("🔍 SEARCHING FOR VOICE CALL MESSAGE BY CALL_SID: #{call_sid}")
        message = conversation.messages
                              .where(content_type: 'voice_call')
                              .where("content_attributes->'data'->>'call_sid' = ?", call_sid)
                              .first
      end

      # If not found, try by looking for a call_sid that contains our call_sid (Twilio sometimes sends partial SIDs)
      if message.nil? && call_sid.present?
        Rails.logger.info("🔍 SEARCHING FOR VOICE CALL MESSAGE BY PARTIAL CALL_SID MATCH: #{call_sid}")
        # Look for messages where call_sid is a substring
        last_few_chars = call_sid.last(8)
        messages = conversation.messages
                               .where(content_type: 'voice_call')
                               .order(created_at: :desc)

        # Manually check for partial matches in content_attributes
        message = messages.find do |msg|
          stored_call_sid = msg.content_attributes.dig('data', 'call_sid')
          stored_call_sid.present? && (stored_call_sid.include?(call_sid) || call_sid.include?(stored_call_sid))
        end
      end

      # If still not found, get the most recent voice call message
      if message.nil?
        Rails.logger.info('🔍 USING MOST RECENT VOICE CALL MESSAGE AS FALLBACK')
        message = conversation.messages
                              .where(content_type: 'voice_call')
                              .order(created_at: :desc)
                              .first
      end

      if message
        Rails.logger.info("✅ FOUND VOICE CALL MESSAGE: #{message.id}")
      else
        Rails.logger.error("❌ NO VOICE CALL MESSAGE FOUND FOR CONVERSATION: #{conversation.id}")
      end

      message
    end

    def create_activity_message(content)
      # Create a simple activity message without additional attributes
      Messages::MessageBuilder.new(
        nil,
        conversation,
        {
          content: content,
          message_type: :activity
        }
      ).perform
    end

    def update_call_status(status, duration = nil)
      # Update conversation attributes
      conversation.additional_attributes ||= {}

      # Only update if status is changing
      previous_status = conversation.additional_attributes['call_status']
      if previous_status == status
        Rails.logger.info("🔄 CALL STATUS UNCHANGED: Already in state '#{status}', no update needed")
        return
      end

      # Log the status change
      Rails.logger.info("📞 CALL STATUS UPDATE: '#{previous_status}' -> '#{status}'")

      # Update the status
      conversation.additional_attributes['call_status'] = status

      # Add timestamps and metadata based on status
      if %w[in-progress active].include?(status)
        # Record the start time if not already set
        unless conversation.additional_attributes['call_started_at']
          conversation.additional_attributes['call_started_at'] = Time.now.to_i
          Rails.logger.info("⏱️ CALL STARTED AT: #{Time.now.to_i}")
        end

        # Ensure we have call meta data
        conversation.additional_attributes['meta'] ||= {}
        conversation.additional_attributes['meta']['active_at'] = Time.now.to_i

        # For active calls, update the UI immediately
        notify_call_status_change(status)
      elsif call_ended?(status)
        # Record end time
        conversation.additional_attributes['call_ended_at'] = Time.now.to_i
        Rails.logger.info("⏱️ CALL ENDED AT: #{Time.now.to_i}")

        # Calculate and record duration
        if duration
          conversation.additional_attributes['call_duration'] = duration
          Rails.logger.info("⏱️ CALL DURATION (provided): #{duration} seconds")
        elsif conversation.additional_attributes['call_started_at']
          conversation.additional_attributes['call_duration'] =
            Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
          Rails.logger.info("⏱️ CALL DURATION (calculated): #{conversation.additional_attributes['call_duration']} seconds")
        end

        # Add call end metadata
        conversation.additional_attributes['meta'] ||= {}
        conversation.additional_attributes['meta']["#{status}_at"] = Time.now.to_i

      end

      # Save the conversation
      begin
        result = conversation.save!
        Rails.logger.info("💾 SAVED CONVERSATION SUCCESSFULLY: conversation_id=#{conversation.id}")
      rescue StandardError => e
        Rails.logger.error("❌ FAILED TO SAVE CONVERSATION: #{e.message}")
        Rails.logger.error("❌ BACKTRACE: #{e.backtrace[0..3].join("\n")}")
      end

      # Broadcast status update for active and ended calls
      notify_call_status_change(status) if call_ended?(status) || status == 'active'
    end

    def call_ended?(status)
      %w[completed busy failed no-answer canceled missed].include?(status)
    end

    def notify_call_status_change(status)
      # For consistency, ensure the conversation values match the notification
      # Sometimes we might have multiple events coming in and want to ensure the final state
      # is reflected correctly in the UI
      conversation.reload

      # If the conversation has a different status than what we're notifying about,
      # use the conversation's status (it may have been updated in another operation)
      final_status = status
      if conversation.additional_attributes['call_status'] != status
        final_status = conversation.additional_attributes['call_status']
        Rails.logger.info("⚠️ STATUS MISMATCH: Notifying: '#{status}', Conversation: '#{final_status}', using conversation value")
      end

      # Construct the notification payload
      notification = {
        event_name: 'call_status_changed',
        data: {
          call_sid: call_sid,
          status: final_status,
          conversation_id: conversation.id,
          timestamp: Time.now.to_i
        }
      }

      # Log the notification for debugging
      Rails.logger.info("📢 BROADCASTING CALL STATUS: '#{final_status}' for conversation_id=#{conversation.id}")

      # Send the notification
      ActionCable.server.broadcast(
        "#{conversation.account_id}_#{conversation.inbox_id}",
        notification
      )
    end
  end
end
