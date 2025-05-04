class Api::V1::Accounts::Channels::Voice::WebhooksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, :set_current_user, only: [:incoming, :conference_status]
  protect_from_forgery with: :null_session, only: [:incoming, :conference_status]
  before_action :validate_twilio_signature, only: [:incoming]
  before_action :handle_options_request, only: [:incoming, :conference_status]
  
  # Handle CORS preflight OPTIONS requests
  def handle_options_request
    if request.method == "OPTIONS"
      set_cors_headers
      head :ok
      return true
    end
    false
  end
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age'] = '86400' # 24 hours
  end

  # Handle incoming calls from Twilio
  def incoming
    # Set CORS headers first to ensure they're included
    set_cors_headers
    
    # Log basic request info
    Rails.logger.info("🔔 INCOMING CALL WEBHOOK: CallSid=#{params['CallSid']} From=#{params['From']} To=#{params['To']}")
    
    # Process incoming call using service
    begin
      # Ensure account is set properly
      if !Current.account && params[:account_id].present?
        Current.account = Account.find(params[:account_id])
        Rails.logger.info("👑 Set Current.account to #{Current.account.id}")
      end
      
      # Validate required parameters
      validate_incoming_params
      
      # Process the call
      service = Voice::IncomingCallService.new(
        account: Current.account, 
        params: params.to_unsafe_h.merge(host_with_port: request.host_with_port)
      )
      twiml_response = service.process
      
      # Return TwiML response
      Rails.logger.info("✅ INCOMING CALL: Successfully processed")
      render xml: twiml_response
    rescue StandardError => e
      # Log the error with detailed information
      Rails.logger.error("❌ INCOMING CALL ERROR: #{e.message}")
      Rails.logger.error("❌ BACKTRACE: #{e.backtrace[0..5].join("\n")}")
      
      # Return friendly error message to caller
      render_error("We're sorry, but we're experiencing technical difficulties. Please try your call again later.")
    end
  end

  # Handle conference status updates
  def conference_status
    # Set CORS headers first to ensure they're always included
    set_cors_headers
    
    # Return immediately for OPTIONS requests
    if request.method == "OPTIONS"
      return head :ok
    end
    
    # Log basic request info
    Rails.logger.info("🎧 CONFERENCE STATUS WEBHOOK: ConferenceSid=#{params['ConferenceSid']} Event=#{params['StatusCallbackEvent']}")
    
    # Process conference status updates using service
    begin
      # Set account for local development if needed
      if !Current.account && params[:account_id].present?
        Current.account = Account.find(params[:account_id])
        Rails.logger.info("👑 Set Current.account to #{Current.account.id}")
      end
      
      # Validate required parameters
      if params['ConferenceSid'].blank? && params['CallSid'].blank?
        Rails.logger.error("❌ MISSING REQUIRED PARAMS: Need either ConferenceSid or CallSid")
      end
      
      # Use service to process conference status
      service = Voice::ConferenceStatusService.new(account: Current.account, params: params)
      service.process
      
      Rails.logger.info("✅ CONFERENCE STATUS: Successfully processed")
    rescue StandardError => e
      # Log errors but don't affect the response
      Rails.logger.error("❌ CONFERENCE STATUS ERROR: #{e.message}")
      Rails.logger.error("❌ BACKTRACE: #{e.backtrace[0..5].join("\n")}")
    end
    
    # Always return a successful response for Twilio
    head :ok
  end

  private

  def validate_incoming_params
    if params['CallSid'].blank?
      raise "Missing required parameter: CallSid"
    end
    
    if params['From'].blank?
      raise "Missing required parameter: From"
    end
    
    if params['To'].blank?
      raise "Missing required parameter: To"
    end
    
    if Current.account.nil?
      raise "Current account not set"
    end
  end

  def validate_twilio_signature
    begin
      validator = Voice::TwilioValidatorService.new(
        account: Current.account,
        params: params,
        request: request
      )
      
      if !validator.valid?
        Rails.logger.error("❌ INVALID TWILIO SIGNATURE")
        render_error('Invalid Twilio signature')
        return false
      end
      
      return true
    rescue StandardError => e
      Rails.logger.error("❌ TWILIO VALIDATION ERROR: #{e.message}")
      render_error('Error validating Twilio request')
      return false
    end
  end

  def render_error(message)
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: message)
    response.hangup
    render xml: response.to_s
  end
end