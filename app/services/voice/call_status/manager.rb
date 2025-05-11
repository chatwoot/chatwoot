module Voice
  module CallStatus
    # CallStatusManager is the centralized service for managing all voice call statuses
    # It handles updating conversation attributes, message attributes, and broadcasting updates.
    # All status changes for voice calls should flow through this service to ensure consistency.
    #
    # This service replaces the older TwilioCallStatusService and MessageUpdateService,
    # centralizing all voice call status management in one place with consistent behavior.
    #
    # Key responsibilities:
    # 1. Tracking call status transitions (initiated → ringing → in-progress → completed)
    # 2. Updating conversation additional_attributes with call metadata
    # 3. Updating voice call message content_attributes with matching status
    # 4. Creating appropriate activity messages for status changes
    # 5. Broadcasting status changes via ActionCable
    # 6. Determining call direction (inbound vs outbound)
    # 7. Providing provider-specific messaging templates
    #
    # Usage:
    #   status_manager = Voice::CallStatus::Manager.new(
    #     conversation: conversation,
    #     call_sid: 'CA123456789',
    #     provider: :twilio
    #   )
    #
    #   # Process a status update (recommended way to update status)
    #   status_manager.process_status_update('completed', 120) # Status with duration in seconds
    #
    #   # Create an activity message
    #   status_manager.create_activity_message('Call ended by agent')
    #
    #   # Check if call is outbound
    #   is_outbound = status_manager.is_outbound?
    class Manager
      # Constructor parameters:
      # - conversation: The conversation associated with the call
      # - call_sid: The external ID for the call from the provider
      # - provider: Symbol representing the provider (e.g., :twilio)
      pattr_initialize [:conversation!, :call_sid, :provider]

      # Valid call statuses with their transitions
      VALID_STATUSES = %w[initiated ringing in-progress active completed missed busy failed no-answer canceled].freeze

      # Terminal statuses that indicate the call has ended
      TERMINAL_STATUSES = %w[completed missed busy failed no-answer canceled].freeze

      # Map external status names to our internal statuses
      STATUS_MAPPING = {
        # Twilio statuses
        'queued' => 'initiated',
        'initiated' => 'initiated',
        'ringing' => 'ringing',
        'in-progress' => 'in-progress',
        'completed' => 'completed',
        'busy' => 'busy',
        'failed' => 'failed',
        'no-answer' => 'no-answer',
        'canceled' => 'canceled',

        # Internal/UI statuses
        'active' => 'in-progress',
        'ended' => 'completed'
      }.freeze

      # Provider-specific message templates for different call statuses
      # These messages must EXACTLY match what the UI expects to show
      # "In-progress" messages have been removed as they don't provide value
      PROVIDER_MESSAGES = {
        twilio: {
          # Status messages (only for terminal statuses)
          'completed' => { outbound: 'Call ended', inbound: 'Call ended' },
          'busy' => { outbound: 'Line busy', inbound: 'Missed call' },
          'failed' => { outbound: 'Call failed', inbound: 'Missed call' },
          'no-answer' => { outbound: 'No answer', inbound: 'Missed call' },
          'canceled' => { outbound: 'Call canceled', inbound: 'Missed call' },
          'missed' => { outbound: 'Call missed', inbound: 'Missed call' }
        }
      }.freeze

      # Create a custom activity message
      # This provides a clean migration path from MessageUpdateService
      def create_activity_message(content, additional_attributes = {})
        return nil if content.blank?
        
        Rails.logger.info("📝 [CallStatusManager] Creating activity message: '#{content}'")
        
        # Create message
        Messages::MessageBuilder.new(
          nil,
          conversation,
          {
            content: content,
            message_type: :activity,
            additional_attributes: additional_attributes
          }
        ).perform
      end

      # Process a call status update from any provider (e.g., Twilio, Vonage)
      # This is the primary method that should be used to update call statuses.
      # It handles different provider statuses, calculates duration, updates conversation
      # and message attributes, and creates appropriate activity messages.
      #
      # @param status [String] The status from the provider (e.g., 'completed', 'ringing')
      # @param duration [Integer, nil] The call duration in seconds (if available)
      # @param is_first_response [Boolean] Whether this is the first status update for this status
      # @param custom_message [String, nil] Optional custom activity message to create
      # @return [Boolean] Whether the update was processed successfully
      def process_status_update(status, duration = nil, is_first_response = false, custom_message = nil)
        # Normalize status using the STATUS_MAPPING if present
        normalized_status = STATUS_MAPPING[status] || status

        # Get current status
        prev_status = conversation.additional_attributes&.dig('call_status')

        # Skip if no changes needed to avoid duplicate processing
        # Unless this is marked as the first response, which we should always process
        if !is_first_response && prev_status == normalized_status
          Rails.logger.info("🔄 [CallStatusManager] Skipping duplicate status update: '#{normalized_status}'")
          return true
        end

        # Handle status transitions - only allow certain transitions
        if prev_status.present? && !is_first_response
          # Don't move backwards in the status flow unless forced to
          if prev_status == 'in-progress' && normalized_status == 'ringing'
            Rails.logger.info("🔄 [CallStatusManager] Skipping backward transition: '#{prev_status}' -> '#{normalized_status}'")
            return true
          end

          # Don't override a completed status with in-progress
          if TERMINAL_STATUSES.include?(prev_status) && normalized_status == 'in-progress'
            Rails.logger.info("🔄 [CallStatusManager] Call already ended, skipping update to: '#{normalized_status}'")
            return true
          end
        end

        # Calculate call duration automatically if not provided and call is ending
        if duration.nil? && call_ended?(normalized_status) && conversation.additional_attributes['call_started_at']
          calculated_duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
          Rails.logger.info("⏱️ [CallStatusManager] Calculated call duration: #{calculated_duration} seconds")
          duration = calculated_duration
        end

        # Update conversation and message status in a database transaction
        result = update_status(normalized_status, duration)

        # Create activity message based on the provided custom message or use default provider message
        if result
          if custom_message.present?
            # Use the custom message provided
            Rails.logger.info("📝 [CallStatusManager] Creating custom activity message: '#{custom_message}'")
            create_activity_message(custom_message, { call_sid: call_sid, call_status: normalized_status })
          elsif should_create_activity_message?(normalized_status)
            # For outbound calls in initiated/ringing stage, only add message if explicitly requested
            if is_outbound? && ['initiated', 'ringing'].include?(normalized_status) && !is_first_response
              Rails.logger.info("📝 [CallStatusManager] Skipping default activity message for outbound call status: '#{normalized_status}'")
            else
              # Use default provider message
              Rails.logger.info("📝 [CallStatusManager] Creating default activity message for status: '#{normalized_status}'")
              create_provider_activity_message(normalized_status, is_first_response)
            end
          end
        end

        result
      end

      # Determine if a call is outbound based on conversation attributes
      # This is the centralized method that should be used throughout the application
      # to determine call direction instead of passing around the is_outbound flag.
      #
      # @return [Boolean] true if the call is outbound, false otherwise
      def is_outbound?
        # Strategy 1: Check the call_direction attribute (most reliable)
        direction = conversation.additional_attributes['call_direction']
        return direction == 'outbound' if direction.present?

        # Strategy 2: Check for requires_agent_join flag (set for outbound calls)
        # When an agent initiates an outbound call, this flag is set to true
        # This helps us identify outbound calls even if call_direction is not set
        return true if conversation.additional_attributes['requires_agent_join'] == true

        # Strategy 3: Check for other outbound indicators
        # e.g., check for call_type or other attributes that might indicate direction
        call_type = conversation.additional_attributes['call_type']
        return true if call_type == 'outbound'

        # Default to inbound if we can't determine
        # Most calls are inbound, so this is a reasonable default
        false
      end
      
      # Convert internal status to UI-friendly status
      # For consistent display across all parts of the UI
      # This is used by other services to ensure consistent status display
      # @param status [String] The raw status to normalize
      # @return [String] The UI-friendly status value
      def normalized_ui_status(status)
        incoming = !is_outbound?
        
        case status
        when 'initiated', 'ringing'
          is_outbound? ? 'started' : 'ringing'
        when 'in-progress', 'active'
          'in_progress'
        when 'completed', 'ended'
          'ended'
        when 'missed'
          is_outbound? ? 'no_answer' : 'missed'
        when 'busy'
          is_outbound? ? 'busy' : 'missed'  # Treat busy as missed for incoming
        when 'failed'
          is_outbound? ? 'failed' : 'missed'  # Treat failed as missed for incoming
        when 'no-answer'
          is_outbound? ? 'no_answer' : 'missed'  # For incoming, this is missed
        when 'canceled'
          is_outbound? ? 'canceled' : 'missed'  # Treat canceled as missed for incoming
        else
          is_outbound? ? 'ended' : 'missed'  # Default to missed for incoming if we don't know
        end
      end

      # Generate provider-specific activity messages (e.g., for Twilio)
      def create_provider_activity_message(status, is_first_response = false)
        # Skip activity messages for non-terminal states
        return nil unless call_ended?(status)
        
        provider_key = provider&.to_sym
        call_direction = is_outbound? ? :outbound : :inbound

        # Default message in case we can't find a provider-specific one
        message = "Call status: #{status}"

        if provider_key && PROVIDER_MESSAGES.key?(provider_key)
          messages = PROVIDER_MESSAGES[provider_key]

          if messages.dig(status, call_direction)
            message = messages.dig(status, call_direction)
          end
        end

        # Create the activity message
        create_activity_message(message, {
                                  call_sid: call_sid,
                                  call_status: status
                                })
      end

      # Update call status in a single operation
      # This ensures conversation and message statuses are in sync
      def update_status(status, duration = nil)
        # Map external status to internal status
        internal_status = STATUS_MAPPING[status] || status

        Rails.logger.info("🔄 [CallStatusManager] Updating call status for conversation #{conversation.display_id}: '#{internal_status}'")

        # Validate status
        unless VALID_STATUSES.include?(internal_status)
          Rails.logger.error("❌ [CallStatusManager] Invalid status: #{internal_status}")
          return false
        end

        # Get current status
        current_status = conversation.additional_attributes['call_status']

        # Only update if status is changing or we're forcing an update
        # Exception: Don't create duplicate "completed" status updates for the same conversation
        if current_status == internal_status
          Rails.logger.info("🔄 [CallStatusManager] Status unchanged: '#{internal_status}'")
          return true
        end

        # Don't process multiple call ending events - once a call is in a terminal state, keep it there
        # This prevents duplicate "Call ended" messages
        if current_status.present? && call_ended?(current_status) && call_ended?(internal_status)
          Rails.logger.info("🔄 [CallStatusManager] Call already in terminal state '#{current_status}', not changing to '#{internal_status}'")
          return true
        end

        # Log the status transition
        Rails.logger.info("🔄 [CallStatusManager] Status transition: '#{current_status}' -> '#{internal_status}'")

        ActiveRecord::Base.transaction do
          # Update conversation additional_attributes
          update_conversation_status(internal_status, duration)

          # Update message content_attributes
          update_message_status(internal_status, duration)

          # Only create activity messages for status changes that warrant them
          # For terminal states, we'll create exactly one appropriate activity message
          # For outbound calls in initiated/ringing states, we'll suppress standard messages
          
          # Track status transitions in conversation metadata to prevent duplicate activity messages
          status_from = conversation.additional_attributes['call_status'] || 'none'
          status_to = internal_status
          transition = "#{status_from}→#{status_to}"
          
          # Store which transitions we've already handled with activity messages
          conversation.additional_attributes['status_transitions'] ||= {}
          transition_handled = conversation.additional_attributes['status_transitions'][transition]
          
          # Mark this transition as handled
          conversation.additional_attributes['status_transitions'][transition] = true
          
          # Only create an activity message for the first occurrence of any status transition
          # and only for terminal states or custom messages
          create_should_activity = should_create_activity_message?(internal_status) && 
                                  !(is_outbound? && ['initiated', 'ringing'].include?(internal_status)) &&
                                  !transition_handled

          # Create activity message for status change if needed
          create_status_activity_message(internal_status) if create_should_activity

          # Broadcast status change notification
          broadcast_status_change(internal_status)
          
          # No need for additional broadcast - status change already broadcasts 
          # conversation.updated events for terminal call states
        end

        true
      rescue StandardError => e
        Rails.logger.error("❌ [CallStatusManager] Error updating status: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
        false
      end

      def call_ended?(status)
        TERMINAL_STATUSES.include?(status)
      end

      private

      def update_conversation_status(status, duration)
        # Update the status
        conversation.additional_attributes ||= {}
        conversation.additional_attributes['call_status'] = status

        # Also store the UI-friendly status for consistent display
        conversation.additional_attributes['ui_call_status'] = normalized_ui_status(status)

        # Update timestamps and metadata based on status
        if %w[in-progress active].include?(status)
          # Record the start time if not already set
          conversation.additional_attributes['call_started_at'] = Time.now.to_i unless conversation.additional_attributes['call_started_at']

          # Ensure we have call meta data
          conversation.additional_attributes['meta'] ||= {}
          conversation.additional_attributes['meta']['active_at'] = Time.now.to_i
        elsif call_ended?(status)
          # Record end time
          conversation.additional_attributes['call_ended_at'] = Time.now.to_i

          # Calculate and record duration
          if duration
            conversation.additional_attributes['call_duration'] = duration
          elsif conversation.additional_attributes['call_started_at']
            conversation.additional_attributes['call_duration'] =
              Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
          end

          # Add call end metadata
          conversation.additional_attributes['meta'] ||= {}
          conversation.additional_attributes['meta']["#{status}_at"] = Time.now.to_i
        end

        # Save the conversation - force timestamp update to trigger UI refresh
        conversation.update!(last_activity_at: Time.current)
      end

      def update_message_status(status, duration)
        message = find_voice_call_message
        return unless message

        # Use the normalized UI status for consistent display
        ui_status = normalized_ui_status(status)

        # Get current content attributes, initialize if needed
        content_attributes = message.content_attributes || {}
        content_attributes['data'] ||= {}

        # Update fields
        content_attributes['data']['status'] = ui_status
        content_attributes['data']['duration'] = duration if duration
        content_attributes['data']['meta'] ||= {}
        content_attributes['data']['meta']["#{ui_status}_at"] = Time.now.to_i
        content_attributes['data']['updated_at'] = Time.now.to_i

        # Add a flag to force the UI to refresh
        content_attributes['data']['status_updated'] = Time.now.to_i

        # Save the message
        message.update!(content_attributes: content_attributes)
      end

      def find_voice_call_message
        # First try to find by call_sid
        message = nil

        if call_sid.present?
          # Try to find by exact call_sid match
          message = conversation.messages
                                .where(content_type: 'voice_call')
                                .where("content_attributes->'data'->>'call_sid' = ?", call_sid)
                                .first
        end

        # If not found, try by looking for a call_sid that contains our call_sid (Twilio sometimes sends partial SIDs)
        if message.nil? && call_sid.present?
          # Look for messages where call_sid is a substring
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
          message = conversation.messages
                                .where(content_type: 'voice_call')
                                .order(created_at: :desc)
                                .first
        end

        message
      end

      def should_create_activity_message?(status)
        # Only create activity messages for terminal call states
        # "in-progress" messages are removed as they don't provide much value
        call_ended?(status)
      end

      def create_status_activity_message(status)
        # Use messages that match the UI expectations exactly
        # These messages will appear in the activity feed
        content = if call_ended?(status)
                    if !is_outbound? 
                      # All ended incoming calls should show as "Missed call" if they weren't answered
                      # Only show "Call ended" if the call was actually answered (in progress)
                      conversation_was_active = conversation.additional_attributes['call_started_at'].present?
                      if conversation_was_active
                        'Call ended'
                      else
                        'Missed call'  # Default for all incoming ended calls that weren't answered
                      end
                    else
                      # For outbound calls, show appropriate endings
                      case status
                      when 'missed'
                        'No answer'
                      when 'busy'
                        'Line busy'
                      when 'failed'
                        'Call failed'
                      when 'no-answer'
                        'No answer'
                      when 'canceled'
                        'Call canceled'
                      else
                        'Call ended'
                      end
                    end
                  else
                    # No intermediate status messages for in-progress or ringing
                    nil
                  end

        # Use the public create_activity_message method
        create_activity_message(content, {
                                  call_sid: call_sid,
                                  call_status: status
                                })
      end

      def broadcast_status_change(status)
        # Broadcast to the account-wide channel
        Rails.logger.info("📢 [CallStatusManager] Broadcasting status change: '#{status}' for conversation_id=#{conversation.id}")

        # Use account-level channel for maximum compatibility
        # Convert the internal status to the UI-friendly format
        # This ensures the conversation list shows consistent status texts
        ui_status = normalized_ui_status(status)

        Rails.logger.info("📢 [CallStatusManager] Broadcasting UI status: '#{ui_status}' for conversation_id=#{conversation.display_id}")

        ActionCable.server.broadcast(
          "account_#{conversation.account_id}",
          {
            event_name: 'call_status_changed',
            data: {
              call_sid: call_sid,
              status: ui_status, # Send UI-friendly status
              conversation_id: conversation.display_id,
              inbox_id: conversation.inbox_id,
              timestamp: Time.now.to_i
            }
          }
        )
        
        # Also broadcast a conversation.updated event for terminal statuses
        # This ensures the conversation list gets refreshed when a call ends
        if call_ended?(status)
          Rails.logger.info("📢 [CallStatusManager] Broadcasting conversation.updated for completed call")
          ActionCable.server.broadcast(
            "account_#{conversation.account_id}",
            {
              event_name: 'conversation.updated',
              data: conversation.push_event_data
            }
          )
        end
      end
    end
  end
end
