require 'twilio-ruby'

class Api::V1::Accounts::Voice::TokensController < Api::V1::Accounts::BaseController
  def create
    # 1. Find inbox
    inbox = Current.account.inboxes.find_by(id: params[:inbox_id])
    
    unless inbox
      render json: { error: 'Inbox not found' }, status: :not_found
      return
    end
    
    # 2. Get Twilio credentials from channel
    channel = inbox.channel
    config = channel.provider_config_hash || {}
    
    # Get Twilio credentials from channel config
    account_sid = config['account_sid']
    auth_token = config['auth_token']
    api_key_sid = config['api_key_sid']
    api_key_secret = config['api_key_secret']
    phone_number = channel.phone_number
    
    # 3. Create a unique client identifier
    client_identity = "agent-#{current_user.id}-#{Current.account.id}"

    # 4. Generate Twilio Access Token
    begin
      # Simple log for debugging
      Rails.logger.debug "Generating Twilio token for identity: #{client_identity} using API key: #{api_key_sid}"
      
      # Create Twilio JWT AccessToken with API key credentials
      token = Twilio::JWT::AccessToken.new(
        account_sid,
        api_key_sid,
        api_key_secret,
        identity: client_identity,
        ttl: 3600
      )
      
      # Create Voice grant for the token
      voice_grant = Twilio::JWT::AccessToken::VoiceGrant.new
      
      # 1. Always enable incoming calls
      voice_grant.incoming_allow = true
      
      # 2. CRITICAL: For outgoing WebRTC calls, we need an application SID (TwiML App SID)
      # This is required to fix error 31002: "Token does not allow outgoing calls"
      outgoing_application_sid = config['outgoing_application_sid']
      
      # For WebRTC calls with Twilio Voice SDK, the outgoing_application_sid is mandatory
      # Without it, browser-based calling won't work properly
      
      if outgoing_application_sid.present?
        # We have a configured TwiML App SID - use it
        voice_grant.outgoing_application_sid = outgoing_application_sid
        
        # Set additional parameters that will be passed to the TwiML app
        # CRITICAL: Include is_agent=true to help identify agent connections on the server side
        voice_grant.outgoing_application_params = {
          'account_id' => Current.account.id.to_s,
          'agent_id' => current_user.id.to_s,
          'identity' => client_identity,
          'client_name' => client_identity,
          'accountSid' => account_sid,
          'is_agent' => 'true' # CRITICAL: Identify agent connections
        }
        
        Rails.logger.info("Using configured TwiML App SID: #{outgoing_application_sid}")
      else
        # Log a clear error message - TwiML App SID is essential for browser-based calling
        twiml_url = "#{ENV.fetch('FRONTEND_URL', '')}/api/v1/accounts/#{Current.account.id}/voice/twiml_for_client"
        
        # Return detailed instructions for setting up TwiML App
        setup_instructions = <<~INSTRUCTIONS
          No TwiML App SID configured! Browser-based calling requires a Twilio TwiML App.
          
          To create a TwiML App:
          1. Go to Twilio Console > Voice > TwiML Apps
          2. Create a new TwiML app
          3. Set the Voice Request URL to: #{twiml_url}
          4. Save and copy the new TwiML App SID 
          5. Update your voice channel configuration with this SID
        INSTRUCTIONS
        
        Rails.logger.error(setup_instructions)
        
        # Still try to create a token, but with a warning that it will likely fail
        # Use a fake App SID to avoid immediate rejection
        voice_grant.outgoing_application_sid = "AP00000000000000000000000000000000"
        
        # Set parameters that would be used if it were a real App SID
        voice_grant.outgoing_application_params = {
          'account_id' => Current.account.id.to_s,
          'agent_id' => current_user.id.to_s,
          'missing_twiml_app' => true  # Flag to indicate the problem
        }
      end
      
      # Log info for detailed debugging
      Rails.logger.info("Voice token created for identity: #{client_identity}")
      Rails.logger.info("Outgoing params: #{voice_grant.outgoing_application_params.inspect}")
      
      # Add the grant to the token
      token.add_grant(voice_grant)

      # Add a warning message if no TwiML App SID is configured
      twiml_url = "#{ENV.fetch('FRONTEND_URL', '')}/api/v1/accounts/#{Current.account.id}/voice/twiml_for_client"
      warning_message = !outgoing_application_sid.present? ? 
        "Browser calling requires a Twilio TwiML App SID. Configure one in the voice channel settings." : nil
      
      # Return token response with additional debugging info
      render json: {
        token: token.to_jwt,
        identity: client_identity,
        voice_enabled: true,
        account_sid: account_sid,
        agent_id: current_user.id,
        account_id: Current.account.id,
        inbox_id: inbox.id,
        phone_number: phone_number,
        twiml_endpoint: twiml_url,
        has_twiml_app: outgoing_application_sid.present?,
        warning: warning_message
      }
    rescue => e
      Rails.logger.error("Error generating token: #{e.message}")
      Rails.logger.error("Backtrace: #{e.backtrace[0..5].join("\n")}")
      
      render json: {
        error: 'Failed to generate token',
        details: e.message
      }, status: :internal_server_error
    end
  end
end