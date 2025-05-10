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

      # Update call status using the unified CallStatusManager
      # The CallStatusManager will determine if the call is outbound internally
      # and will create an appropriate activity message
      custom_message = "Call ended by #{current_user.name}"
      
      status_manager = Voice::CallStatus::Manager.new(
        conversation: @conversation, 
        call_sid: call_sid,
        provider: :twilio
      )
      status_manager.process_status_update('completed', nil, false, custom_message)
      
      # No need to create additional activity messages - the manager handles it
      
      # Broadcast call status update on the account channel
      ActionCable.server.broadcast(
        "account_#{@conversation.account_id}",
        {
          event_name: 'call_status_changed',
          data: {
            call_sid: call_sid,
            status: 'completed',
            conversation_id: @conversation.display_id,
            inbox_id: @conversation.inbox_id,
            timestamp: Time.now.to_i
          }
        }
      )

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
      # Make sure we have a valid account ID
      account_id = Current.account&.id || params[:account_id]

      # Make sure the conversation is fully loaded with display_id
      if @conversation.display_id.blank?
        @conversation.reload
        Rails.logger.info("🔄 Reloaded conversation to get display_id")
      end

      # Extra logging for debugging
      Rails.logger.info("🔍 Creating conference with account_id=#{account_id}, conversation.display_id=#{@conversation.display_id}")

      # Use the same format as in webhooks_controller for consistency
      # Ensure all parts of the conference ID are present
      if account_id.present? && @conversation.display_id.present?
        conference_sid = "conf_account_#{account_id}_conv_#{@conversation.display_id}"
      else
        # Fallback with more diagnostic information
        Rails.logger.error("❌ Missing account ID or conversation display ID for conference creation")
        Rails.logger.error("❌ account_id=#{account_id}, conversation.display_id=#{@conversation.display_id}")
        # Create a valid conference ID with as much information as we have
        account_id ||= "unknown"
        conversation_id = @conversation.display_id || @conversation.id || "unknown"
        conference_sid = "conf_account_#{account_id}_conv_#{conversation_id}"
      end

      # Save it for future use
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['conference_sid'] = conference_sid
      @conversation.save!

      # Log the created conference
      Rails.logger.info("🎧 Created new conference: #{conference_sid}")
    end

    # For outbound calls, ensure we also update call_status if not already set
    if is_outbound_call && !@conversation.additional_attributes['call_status']
      @conversation.additional_attributes['call_status'] = 'in-progress'
      @conversation.save!
      # Set call status for outbound call
    end

    # Agent joining call via WebRTC

    # Update conversation to show agent joined
    @conversation.additional_attributes['agent_joined'] = true
    @conversation.additional_attributes['joined_at'] = Time.now.to_i
    @conversation.additional_attributes['joined_by'] = {
      id: current_user.id,
      name: current_user.name
    }

    # Update call status using the unified CallStatusManager with custom message
    # The CallStatusManager will determine if the call is outbound internally
    custom_message = "#{current_user.name} joined the call"
    
    status_manager = Voice::CallStatus::Manager.new(
      conversation: @conversation, 
      call_sid: call_sid,
      provider: :twilio
    )
    status_manager.process_status_update('in-progress', nil, false, custom_message)

    # Save the conversation with agent join details
    @conversation.save!
    
    # Broadcast call status update on the account channel
    ActionCable.server.broadcast(
      "account_#{@conversation.account_id}",
      {
        event_name: 'call_status_changed',
        data: {
          call_sid: call_sid,
          status: 'in-progress',
          conversation_id: @conversation.display_id,
          inbox_id: @conversation.inbox_id,
          timestamp: Time.now.to_i
        }
      }
    )

    # Return conference information for the WebRTC client
    response_data = {
      status: 'success',
      message: 'Agent joining call via WebRTC',
      conference_sid: conference_sid,
      using_webrtc: true,
      conversation_id: @conversation.display_id,
      account_id: Current.account.id
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

    # Update call status and create activity message through the unified manager
    custom_message = "#{current_user.name} declined to answer"
    
    status_manager = Voice::CallStatus::Manager.new(
      conversation: @conversation, 
      call_sid: call_sid,
      provider: :twilio
    )
    status_manager.create_activity_message(custom_message, {
      call_sid: call_sid,
      rejected_by: current_user.name,
      rejected_at: Time.now.to_i
    })

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
    # Extended debugging to trace the request
    Rails.logger.info("🔄 TwiML_FOR_CLIENT CALLED with params: #{params.inspect}")
    Rails.logger.info("🔄 Headers: #{request.headers.to_h.select {|k,v| k.start_with?('HTTP_')}.inspect}")
    Rails.logger.info("🔄 Content-Type: #{request.content_type}")
    Rails.logger.info("🔄 Raw POST data: #{request.raw_post}")

    # Check what account we're using
    account_id_value = params[:account_id]
    current_account_id = Current.account&.id
    Rails.logger.info("📞 TwiML account context - params[:account_id]: #{account_id_value}, Current.account.id: #{current_account_id}")

    # SUPER DETAILED PARAMETER INSPECTION
    Rails.logger.info("📞 FULL PARAMS INSPECTION:")
    params.each do |key, value|
      Rails.logger.info("   - #{key.inspect} = #{value.inspect}")
    end

    # Check for 'To' parameter in different formats
    to = params[:To] || params[:to] || params['To'] || params['to']

    # IMPORTANT DEBUG: Log all possible parameters that might contain the conference ID
    Rails.logger.info("📞 Trying to find conference ID in params:")
    Rails.logger.info("   - params[:To] = #{params[:To].inspect}")
    Rails.logger.info("   - params[:to] = #{params[:to].inspect}")
    Rails.logger.info("   - params['To'] = #{params['To'].inspect}")
    Rails.logger.info("   - params['to'] = #{params['to'].inspect}")

    # Also try the Twilio default params format
    Rails.logger.info("   - params['Twilio-Parameters'] = #{params['Twilio-Parameters'].inspect}")

    # Parse raw POST body for Twilio params
    if request.post? && request.raw_post.present?
      begin
        post_params = Rack::Utils.parse_nested_query(request.raw_post)
        Rails.logger.info("   - POST body parsed: #{post_params.inspect}")
        if post_params['To'].present?
          to ||= post_params['To']
          Rails.logger.info("   - Found 'To' in POST body: #{post_params['To']}")
        end
      rescue => e
        Rails.logger.error("   - Error parsing POST body: #{e.message}")
      end
    end

    # Now check if we have a valid 'To' parameter
    if to.blank?
      Rails.logger.error("❌ Missing 'To' parameter in all possible forms")
      Rails.logger.error("❌ ALL PARAMS: #{params.inspect}")

      error_response = Twilio::TwiML::VoiceResponse.new
      error_response.say(message: "Error: Missing conference ID parameter.")
      error_response.hangup
      set_cors_headers
      render xml: error_response.to_s, content_type: 'text/xml'
      return
    end

    # Log the conference ID
    Rails.logger.info("📞 Using conference ID: '#{to}'")

    # Make the TwiML response generation as simple as possible
    response = Twilio::TwiML::VoiceResponse.new do |r|
      # Log everything about the request
      # Generate TwiML for agent to join conference

      # SIMPLEST POSSIBLE APPROACH - direct conference connection without any extra audio
      r.dial do |dial|
        # Using this conference name in TwiML

        # Simple callback URL construction with safe fallback for Current.account
        account_id = params[:account_id] || (Current.account&.id) || '2' # Use URL param, Current.account, or fallback
        base_callback_url = "#{base_url.gsub(%r{/$}, '')}/api/v1/accounts/#{account_id}/channels/voice/webhooks/conference_status"

        # Use agent_id directly or default to '1'
        agent_id = params['agent_id'].presence || '1'

        # Log connection parameters
        is_agent = params['is_agent'] == 'true'
        Rails.logger.info("🔥 AGENT CONNECTING: conf=#{to}, agent_id=#{agent_id}")

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
    Rails.logger.info("🔍 DEBUG: Agent joining as PARTICIPANT to conference '#{to}' with account_id=#{params[:account_id]}")

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
    @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
  end

  # Voice call message related functionality is now handled by Voice::CallStatus::Manager

  # Helper method to get base URL with extra resilience
  def base_url
    ENV.fetch('FRONTEND_URL', nil)
  end
end
