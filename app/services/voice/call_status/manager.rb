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
      PROVIDER_MESSAGES = {
        twilio: {
          'initiated' => { outbound: 'Outbound call initiated', inbound: 'Initiating call' },
          'ringing' => { outbound: 'Phone ringing', inbound: 'Phone ringing' },
          'in-progress' => {
            outbound: { first: 'Call connected', next: 'Call in progress' },
            inbound: { first: 'Call answered', next: 'Call in progress' }
          },
          'completed' => { outbound: 'Call completed', inbound: 'Call completed' },
          'busy' => { outbound: 'Call busy', inbound: 'Call busy' },
          'failed' => { outbound: 'Call failed', inbound: 'Call failed' },
          'no-answer' => { outbound: 'Call not answered', inbound: 'Call not answered' },
          'canceled' => { outbound: 'Call canceled', inbound: 'Call canceled' }
        }
      }.freeze

      # Create a custom activity message
      # This provides a clean migration path from MessageUpdateService
      def create_activity_message(content, additional_attributes = {})
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
      # @return [Boolean] Whether the update was processed successfully
      def process_status_update(status, duration = nil, is_first_response = false)
        # Skip if no changes needed to avoid duplicate processing
        # Unless this is marked as the first response, which we should always process
        prev_status = conversation.additional_attributes&.dig('call_status')
        if !is_first_response && prev_status == status
          Rails.logger.info("🔄 [CallStatusManager] Skipping duplicate status update: '#{status}'")
          return true
        end

        # Normalize status using the STATUS_MAPPING if present
        normalized_status = STATUS_MAPPING[status] || status

        # Calculate call duration automatically if not provided and call is ending
        if duration.nil? && call_ended?(normalized_status) && conversation.additional_attributes['call_started_at']
          calculated_duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
          Rails.logger.info("⏱️ [CallStatusManager] Calculated call duration: #{calculated_duration} seconds")
          duration = calculated_duration
        end

        # Update conversation and message status in a database transaction
        result = update_status(normalized_status, duration)

        # Create an activity message with provider-specific text if status was updated
        create_provider_activity_message(normalized_status, is_first_response) if result

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

      # Generate provider-specific activity messages (e.g., for Twilio)
      def create_provider_activity_message(status, is_first_response = false)
        provider_key = provider&.to_sym
        call_direction = is_outbound? ? :outbound : :inbound

        # Default message in case we can't find a provider-specific one
        message = "Call status: #{status}"

        if provider_key && PROVIDER_MESSAGES.key?(provider_key)
          messages = PROVIDER_MESSAGES[provider_key]

          if status == 'in-progress' && messages.dig(status, call_direction).is_a?(Hash)
            message_type = is_first_response ? :first : :next
            provider_message = messages.dig(status, call_direction, message_type)
            message = provider_message if provider_message
          elsif messages.dig(status, call_direction)
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

        Rails.logger.info("🔄 [CallStatusManager] Updating call status for conversation #{conversation.id}: '#{internal_status}'")

        # Validate status
        unless VALID_STATUSES.include?(internal_status)
          Rails.logger.error("❌ [CallStatusManager] Invalid status: #{internal_status}")
          return false
        end

        # Get current status
        current_status = conversation.additional_attributes['call_status']

        # Only update if status is changing or we're forcing an update
        if current_status == internal_status
          Rails.logger.info("🔄 [CallStatusManager] Status unchanged: '#{internal_status}'")
          return true
        end

        # Log the status transition
        Rails.logger.info("🔄 [CallStatusManager] Status transition: '#{current_status}' -> '#{internal_status}'")

        ActiveRecord::Base.transaction do
          # Update conversation additional_attributes
          update_conversation_status(internal_status, duration)

          # Update message content_attributes
          update_message_status(internal_status, duration)

          # Create activity message for status change if it's a significant change
          create_status_activity_message(internal_status) if should_create_activity_message?(internal_status)

          # Broadcast status change notification
          broadcast_status_change(internal_status)
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

        # Save the conversation
        conversation.save!
      end

      def update_message_status(status, duration)
        message = find_voice_call_message
        return unless message

        # Determine best message status value based on conversation status
        message_status = status
        if status == 'in-progress'
          message_status = 'active'
        elsif call_ended?(status)
          message_status = 'ended'
        end

        # Get current content attributes, initialize if needed
        content_attributes = message.content_attributes || {}
        content_attributes['data'] ||= {}

        # Update fields
        content_attributes['data']['status'] = message_status
        content_attributes['data']['duration'] = duration if duration
        content_attributes['data']['meta'] ||= {}
        content_attributes['data']['meta']["#{message_status}_at"] = Time.now.to_i
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
        # Only create activity messages for significant state changes
        # Avoid creating too many messages for intermediate states
        call_ended?(status) || status == 'in-progress'
      end

      def create_status_activity_message(status)
        content = if call_ended?(status)
                    case status
                    when 'missed'
                      'Call was not answered'
                    when 'busy'
                      'Line was busy'
                    when 'failed'
                      'Call failed'
                    when 'no-answer'
                      'No answer'
                    when 'canceled'
                      'Call was canceled'
                    else
                      'Call ended'
                    end
                  elsif status == 'in-progress'
                    'Call in progress'
                  else
                    "Call status changed to #{status}"
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
        ActionCable.server.broadcast(
          "account_#{conversation.account_id}",
          {
            event_name: 'call_status_changed',
            data: {
              call_sid: call_sid,
              status: status,
              conversation_id: conversation.id,
              inbox_id: conversation.inbox_id,
              timestamp: Time.now.to_i
            }
          }
        )
      end
    end
  end
end
