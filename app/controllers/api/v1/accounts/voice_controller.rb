require 'twilio-ruby'

class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:end_call, :join_call, :reject_call]
  skip_before_action :authenticate_user!, only: [:twiml_for_client]
  # Removed skip_before_action :verify_authenticity_token (it's not defined in BaseController)
  protect_from_forgery with: :null_session, only: [:twiml_for_client]
  before_action :handle_options_request, only: [:twiml_for_client]

  # Handle CORS preflight OPTIONS requests
  def handle_options_request
    if request.method == 'OPTIONS'
      set_cors_headers
      head :ok
      return true
    end
    false
  end

  def set_cors_headers
    # Add explicit Content-Type header to ensure browser requests are handled properly
    headers['Content-Type'] = 'text/xml; charset=utf-8' unless request.method == 'OPTIONS'

    # Standard CORS headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age'] = '86400' # 24 hours

    # Log headers for debugging
    Rails.logger.info("🚨 RESPONSE HEADERS SET: #{headers.to_h.inspect}")
  end

  # No hard-coded credentials - we'll fetch them from the channel

  def end_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid

    # Get the channel config
    channel = @conversation.inbox.channel
    config = channel.provider_config_hash

    # Create a Twilio client using credentials from the channel
    client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
    call = client.calls(call_sid).fetch

    # Only try to end the call if it's still in progress
    if call.status == 'in-progress' || call.status == 'ringing'
      client.calls(call_sid).update(status: 'completed')

      # Update conversation call status
      @conversation.additional_attributes['call_status'] = 'completed'
      @conversation.additional_attributes['call_ended_at'] = Time.now.to_i

      # Calculate call duration if we have a start time
      if @conversation.additional_attributes['call_started_at']
        @conversation.additional_attributes['call_duration'] = Time.now.to_i - @conversation.additional_attributes['call_started_at'].to_i
      end

      # Update the voice call message status
      if call_message = find_voice_call_message
        content_attributes = call_message.content_attributes || {}
        content_attributes['data'] ||= {}
        content_attributes['data']['status'] = 'completed'
        content_attributes['data']['status_updated'] = Time.now.to_i
        content_attributes['data']['meta'] ||= {}
        content_attributes['data']['meta']['completed_at'] = Time.now.to_i
        content_attributes['data']['ended_at'] = Time.now.to_i

        # Add duration if available
        if @conversation.additional_attributes['call_duration']
          content_attributes['data']['duration'] = @conversation.additional_attributes['call_duration']
        end

        call_message.update(content_attributes: content_attributes)
      end

      @conversation.save!

      # Create an activity message noting the call has ended
      Messages::MessageBuilder.new(
        nil,
        @conversation,
        {
          content: 'Call ended by agent',
          message_type: :activity,
          additional_attributes: {
            call_sid: call_sid,
            call_status: 'completed',
            ended_by: current_user.name
          }
        }
      ).perform

      render json: { status: 'success', message: 'Call successfully ended' }
    else
      render json: { status: 'success', message: "Call already in '#{call.status}' state" }
    end
  rescue StandardError => e
    render json: { error: "Failed to end call: #{e.message}" }, status: :internal_server_error
  end

  def join_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')

    # Check if this is an outbound call that needs to be joined (might not have call_sid yet)
    is_outbound_call = @conversation.additional_attributes&.dig('requires_agent_join') == true

    return render json: { error: 'No active call found' }, status: :not_found unless call_sid || is_outbound_call

    # Get the conference SID from the conversation
    conference_sid = @conversation.additional_attributes&.dig('conference_sid')

    # Check conversation record for conference information

    # If not found, create one using account ID and conversation display ID
    if conference_sid
      # Using existing conference
    else
      # Use the same format as in webhooks_controller for consistency
      conference_sid = "conf_account_#{Current.account.id}_conv_#{@conversation.display_id}"

      # Save it for future use
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['conference_sid'] = conference_sid
      @conversation.save!

      # Created new conference
    end

    # For outbound calls, ensure we also update call_status if not already set
    if is_outbound_call && !@conversation.additional_attributes['call_status']
      @conversation.additional_attributes['call_status'] = 'in-progress'
      @conversation.save!
      # Set call status for outbound call
    end

    # Agent joining call via WebRTC

    # Update conversation to show agent joined and set call status to active
    @conversation.additional_attributes['agent_joined'] = true
    @conversation.additional_attributes['joined_at'] = Time.now.to_i
    @conversation.additional_attributes['joined_by'] = {
      id: current_user.id,
      name: current_user.name
    }

    # CRITICAL: Update call status to 'in-progress' to ensure UI updates properly
    # This is especially important for incoming calls where the status might not get updated otherwise
    @conversation.additional_attributes['call_status'] = 'in-progress'

    # Also record started_at timestamp if not already set
    @conversation.additional_attributes['call_started_at'] = Time.now.to_i unless @conversation.additional_attributes['call_started_at']

    # Update the call data in the voice call message
    if call_message = find_voice_call_message
      content_attributes = call_message.content_attributes || {}
      content_attributes['data'] ||= {}
      content_attributes['data']['status'] = 'in-progress'
      content_attributes['data']['status_updated'] = Time.now.to_i
      content_attributes['data']['meta'] ||= {}
      content_attributes['data']['meta']['active_at'] = Time.now.to_i
      call_message.update(content_attributes: content_attributes)
    end

    @conversation.save!

    # Create an activity message
    Messages::MessageBuilder.new(
      nil,
      @conversation,
      {
        content: "#{current_user.name} joined the call",
        message_type: :activity,
        additional_attributes: {
          call_sid: call_sid,
          conference_sid: conference_sid,
          joined_by: current_user.name,
          joined_at: Time.now.to_i
        }
      }
    ).perform

    # Return conference information for the WebRTC client with detailed logging
    response_data = {
      status: 'success',
      message: 'Agent joining call via WebRTC',
      conference_sid: conference_sid,
      using_webrtc: true,
      # Add useful debugging info
      conversation_id: @conversation.display_id,
      account_id: Current.account.id,
      # Add even more debug info
      conference_name_debug: "#{conference_sid}"
    }

    # Return response with conference information

    render json: response_data
  rescue StandardError => e
    Rails.logger.error("Error joining call: #{e.message}")
    render json: { error: "Failed to join call: #{e.message}" }, status: :internal_server_error
  end

  def reject_call
    call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid

    # Update conversation to show agent rejected call
    @conversation.additional_attributes['agent_rejected'] = true
    @conversation.additional_attributes['rejected_at'] = Time.now.to_i
    @conversation.additional_attributes['rejected_by'] = {
      id: current_user.id,
      name: current_user.name
    }
    @conversation.save!

    # Create an activity message noting the agent rejected the call
    Messages::MessageBuilder.new(
      nil,
      @conversation,
      {
        content: "#{current_user.name} declined to answer",
        message_type: :activity,
        additional_attributes: {
          call_sid: call_sid,
          rejected_by: current_user.name,
          rejected_at: Time.now.to_i
        }
      }
    ).perform

    render json: {
      status: 'success',
      message: 'Call rejected by agent'
    }
  end

  def call_status
    call_sid = params[:call_sid]
    return render json: { error: 'No active call found' }, status: :not_found unless call_sid

    conversation = Current.account.conversations.where("additional_attributes->>'call_sid' = ?", call_sid).first
    return render json: { error: 'Conversation not found' }, status: :not_found unless conversation

    # Get the channel config
    channel = conversation.inbox.channel
    config = channel.provider_config_hash

    begin
      # Create a Twilio client using credentials from the channel
      client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
      call = client.calls(call_sid).fetch

      render json: {
        status: call.status,
        duration: call.duration,
        direction: call.direction,
        from: call.from,
        to: call.to,
        start_time: call.start_time,
        end_time: call.end_time
      }
    rescue StandardError => e
      render json: { error: "Failed to fetch call status: #{e.message}" }, status: :internal_server_error
    end
  end

  # TwiML endpoint for Twilio Client browser calls - with ultra-robust error handling
  def twiml_for_client
    # Log everything for debugging
    Rails.logger.info("TwiML_FOR_CLIENT CALLED with params: #{params.inspect}")

    # Extract just what we need - the To parameter (conference name)
    # Check for the To parameter which should be sent by the Twilio client
    to = params[:To]

    # Simple debug log of what we received
    Rails.logger.info("📞 Received request for TwiML with To parameter: '#{to}'")

    # Verify the format is what we expect
    if to && to.match?(/^conf_account_\d+_conv_\d+$/)
      Rails.logger.info("✅ Conference ID is in the expected format: #{to}")
    elsif to
      Rails.logger.info("⚠️ Conference ID does not match expected format: #{to}")
    end

    # SUPER CRITICAL DEBUGGING - We need to know EXACTLY what is coming in as the To parameter
    Rails.logger.info("🚨 PARAMS INSPECTION: #{params.to_json}")
    Rails.logger.info("🚨 TO PARAMETER (CAPS) EXISTS?: #{params.key?(:To)}")
    Rails.logger.info("🚨 TO PARAMETER (LOWERCASE) EXISTS?: #{params.key?(:to)}")
    Rails.logger.info("🚨 TO PARAMETER FINAL VALUE: '#{to}'")
    Rails.logger.info("🚨 TO PARAMETER TYPE: #{to.class}")
    Rails.logger.info("🚨 TO PARAMETER EMPTY?: #{to.blank?}")
    Rails.logger.info("🚨 TO PARAMETER STARTS WITH 'conf_'?: #{to.to_s.start_with?('conf_')}")

    # Critical debugging for troubleshooting
    Rails.logger.info("PARAMS RECEIVED: #{params.inspect}")
    Rails.logger.info("REQUEST HEADERS: #{request.headers.to_h.select { |k, _| k.start_with?('HTTP_') }.inspect}")
    Rails.logger.info("CLIENT IP: #{request.remote_ip}")

    # Log missing to parameter and try to find the correct conference ID
    if to.blank?
      # Log the issue clearly
      Rails.logger.error("🚨 Missing 'To' parameter in request! Trying to find the correct conference ID")

      # Get account ID from params
      account_id = params[:account_id]

      if account_id.present?
        # Find the latest active call for this account
        Rails.logger.info("🔍 Looking for latest active call for account #{account_id}")

        begin
          # Find the most recent conversation with an active call
          conversation = Conversation.joins(:inbox)
                                     .where(account_id: account_id)
                                     .where("additional_attributes->>'call_status' IN ('ringing', 'in-progress')")
                                     .where("additional_attributes ? 'conference_sid'")
                                     .order(created_at: :desc)
                                     .first

          if conversation
            # Use the exact conference ID from the conversation
            to = conversation.additional_attributes['conference_sid']

            if to && to.start_with?('conf_account_') && to.include?('_conv_')
              Rails.logger.info("✅ Found active call with conference ID: #{to}")
            else
              Rails.logger.error("❌ Found conversation but conference ID format is invalid: #{to}")
            end
          else
            Rails.logger.error("❌ No active calls found for account #{account_id}")
          end
        rescue StandardError => e
          Rails.logger.error("❌ Error finding active call: #{e.message}")
        end
      end

      # If we still don't have a valid To parameter, use a well-known format that will fail predictably
      if to.blank?
        to = 'MISSING_TO_PARAMETER'
        Rails.logger.error('❌ Could not find a valid conference ID - call will fail')
      end
    end

    # CRITICAL: Do NOT modify the conference name - simply ensure it's a string
    # This was the source of the issue - we were adding an extra prefix even when it already had one
    to = to.to_s

    # Log the final conference name
    Rails.logger.info("FINAL CONFERENCE NAME: #{to}")

    # IMPROVED Account handling - more resilient with better logging
    account_id = params[:account_id].presence
    Rails.logger.info("ACCOUNT_ID FROM PARAMS: #{account_id.inspect}")

    # Safer account ID validation
    begin
      account = nil
      if account_id.present?
        # Try to parse as integer for safer lookup
        safe_account_id = account_id.to_i
        account = Account.find_by(id: safe_account_id)

        if account
          Rails.logger.info("✅ Found account with ID: #{safe_account_id}")
        else
          Rails.logger.warn("⚠️ No account found with ID: #{safe_account_id}")
        end
      end

      # Fallback chain - try multiple ways to find an account
      if account.nil?
        Rails.logger.info('Looking for first account as fallback')
        account = Account.first

        if account
          Rails.logger.info("✅ Found fallback account with ID: #{account.id}")
        else
          Rails.logger.error('❌ No accounts exist in the system!')
        end
      end

      # Set current account if found
      if account
        Current.account = account
        Rails.logger.info("✅ Current.account set to ID: #{account.id}")
      end
    rescue StandardError => e
      Rails.logger.error("❌ Error setting Current.account: #{e.message}")
      Rails.logger.error(e.backtrace.first(3).join("\n"))
    end

    # Make the TwiML response generation as simple as possible
    response = Twilio::TwiML::VoiceResponse.new do |r|
      # Log everything about the request
      # Generate TwiML for agent to join conference

      # SIMPLEST POSSIBLE APPROACH - direct conference connection without any extra audio
      r.dial do |dial|
        # Using this conference name in TwiML

        # Get a safe callback URL
        base_callback_url = if Current.account&.id
                              "#{base_url.gsub(%r{/$}, '')}/api/v1/accounts/#{Current.account.id}/channels/voice/webhooks/conference_status"
                            else
                              "#{base_url.gsub(%r{/$}, '')}/api/v1/accounts/1/channels/voice/webhooks/conference_status"
                            end

        # Agent ID for participant label
        agent_id = current_user.present? ? current_user.id.to_s : 'unknown-user'

        # Log connection parameters to help debug outbound call issues
        is_agent = params['is_agent'] == 'true'
        Rails.logger.info("🔥🔥🔥 AGENT CONNECTING TO CONFERENCE: #{to}, agent_id=#{agent_id}, is_agent=#{is_agent}")

        # CRITICAL: Look for outbound call indicators in URL parameters
        Rails.logger.info('🚨🚨🚨 DETECTED OUTBOUND CALL OR AGENT CONNECTING') if params['is_outbound'] == 'true' || is_agent

        # Absolute minimal conference parameters for agent joining
        dial.conference(
          to,
          startConferenceOnEnter: true,    # Agent joining starts the conference
          endConferenceOnExit: true,       # End when agent leaves
          muted: false,                    # Agent can speak
          beep: false,                     # No beep sounds
          waitUrl: '',                     # No hold music
          earlyMedia: true,                # Enable early media for faster connection
          statusCallback: base_callback_url,
          statusCallbackEvent: 'start end join leave',
          statusCallbackMethod: 'POST',
          participantLabel: "agent-#{agent_id}"
        )
      end
    end

    # Extra logging to help diagnose issues
    Rails.logger.info("🎧 TwiML conference parameters for agent: startConferenceOnEnter=true, endConferenceOnExit=true, conference_name=#{to}")
    Rails.logger.info("🔊 Generated TwiML length: #{response.to_s.length} bytes")
    # Add more detailed debugging about what we're actually doing
    Rails.logger.info("🔍 DEBUG: Agent joining as PARTICIPANT to conference '#{to}' with account_id=#{account_id}")

    # Set CORS headers to properly respond to Twilio
    set_cors_headers

    # Render with proper MIME type
    render xml: response.to_s, content_type: 'text/xml'
  rescue StandardError => e
    # Enhanced error logging
    Rails.logger.error("💥 ERROR IN TWIML GENERATION: #{e.class.name}: #{e.message}")
    Rails.logger.error("💥 EXCEPTION BACKTRACE: #{e.backtrace.first(10).join("\n")}")
    Rails.logger.error("💥 PARAMS AT TIME OF ERROR: #{params.inspect}")

    # Generate a super-simple error response that explains the issue
    error_response = Twilio::TwiML::VoiceResponse.new
    error_response.say(message: 'We apologize, but there was a technical issue connecting your call.')
    error_response.pause(length: 1)
    error_response.say(message: "The specific error was: #{e.message[0..100]}")
    error_response.pause(length: 1)
    error_response.say(message: 'The call will now disconnect. Please try again.')
    error_response.hangup

    # Set CORS headers
    set_cors_headers

    render xml: error_response.to_s, content_type: 'text/xml'
  end

  # Helper method to render TwiML error response with minimal parameters
  def render_twiml_error(message)
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say(message: "Error: #{message}")
      r.hangup
    end

    render xml: response.to_s, content_type: 'text/xml'
  rescue StandardError => e
    # Last resort error handling
    Rails.logger.error("💥 ERROR IN ERROR HANDLER: #{e.message}")
    render plain: '<?xml version="1.0" encoding="UTF-8"?><Response><Say>Error occurred</Say><Hangup/></Response>', content_type: 'text/xml'
  end

  private

  def fetch_conversation
    @conversation = Current.account.conversations.find(params[:id] || params[:conversation_id])
  end

  # Helper method to find the voice call message for the current call
  # Similar to the one in Voice::MessageUpdateService but simplified
  def find_voice_call_message
    return nil unless @conversation.present?

    # Try to find by call_sid first
    if call_sid = params[:call_sid] || @conversation.additional_attributes&.dig('call_sid')
      message = @conversation.messages
                             .where(content_type: 'voice_call')
                             .where("content_attributes->'data'->>'call_sid' = ?", call_sid)
                             .first

      # If found, return it
      return message if message
    end

    # Fall back to the most recent voice call message
    @conversation.messages
                 .where(content_type: 'voice_call')
                 .order(created_at: :desc)
                 .first
  end

  # Helper method to get base URL with extra resilience
  def base_url
    # Try several methods to determine the base URL, with detailed logging
    base = nil
    source = nil

    begin
      # First, try request.base_url if available
      if defined?(request) && request&.respond_to?(:base_url) && request.base_url.present?
        base = request.base_url
        source = 'request.base_url'
        Rails.logger.info("✅ Got base_url from request: #{base}")
      end

      # If not available, check for Rails.application.routes.default_url_options
      if base.nil? && defined?(Rails) && Rails.application&.routes&.respond_to?(:default_url_options)
        options = Rails.application.routes.default_url_options
        if options && options[:host].present?
          protocol = options[:protocol] || 'http'
          port = options[:port].present? ? ":#{options[:port]}" : ''
          base = "#{protocol}://#{options[:host]}#{port}"
          source = 'Rails.application.routes.default_url_options'
          Rails.logger.info("✅ Got base_url from Rails routes: #{base}")
        end
      end

      # Check for specific Chatwoot ENV variables
      if base.nil?
        frontend_url = ENV.fetch('FRONTEND_URL', nil)
        if frontend_url.present?
          base = frontend_url
          source = 'FRONTEND_URL env var'
          Rails.logger.info("✅ Got base_url from FRONTEND_URL env var: #{base}")
        end
      end

      # Check for additional Chatwoot ENV variables
      if base.nil?
        api_url = ENV.fetch('API_URL', nil)
        if api_url.present?
          base = api_url.to_s.gsub(%r{/api/v\d+/?$}, '') # Remove API version path if present
          source = 'API_URL env var'
          Rails.logger.info("✅ Got base_url from API_URL env var: #{base}")
        end
      end

      # Try to use Current account domain
      if base.nil? && Current.account&.domain.present?
        base = "https://#{Current.account.domain}"
        source = 'Current.account.domain'
        Rails.logger.info("✅ Got base_url from Current.account.domain: #{base}")
      end

      # Detect local development environments
      if base.nil? && (request&.host == 'localhost' || request&.host&.include?('.local'))
        port = request&.port || 3000
        base = "http://#{request.host}:#{port}"
        source = 'localhost detection'
        Rails.logger.info("✅ Detected localhost development: #{base}")
      end

      # Ultimate fallback - use either a sojan-local.chatwoot.dev pattern or localhost
      if base.nil?
        if request&.host.present? && request.host.include?('chatwoot')
          base = "https://#{request.host}"
          source = 'request.host fallback for chatwoot domain'
        else
          base = 'http://localhost:3000'
          source = 'localhost hardcoded fallback'
        end
        Rails.logger.info("⚠️ Using fallback base_url: #{base} (source: #{source})")
      end

      # Ensure base URL doesn't have a trailing slash
      base = base.chomp('/') if base

      # Additional safeguard
      unless base.to_s.match?(%r{^https?://})
        base = "http://#{base}"
        Rails.logger.warn("⚠️ Added missing protocol to base_url: #{base}")
      end

      Rails.logger.info("🌐 FINAL base_url: #{base} (source: #{source})")
      base
    rescue StandardError => e
      # If all else fails, return localhost but log the error
      Rails.logger.error("❌ Error determining base URL: #{e.message}")
      Rails.logger.error(e.backtrace.first(3).join("\n"))
      'http://localhost:3000'
    end
  end
end
