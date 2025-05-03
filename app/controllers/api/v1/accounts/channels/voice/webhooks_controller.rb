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
    # Process incoming call using service
    service = Voice::IncomingCallService.new(account: Current.account, params: params.merge(host_with_port: request.host_with_port))
    twiml_response = service.process
    
    # Return TwiML response
    render xml: twiml_response
  rescue => e
    Rails.logger.error("Error processing incoming call: #{e.message}")
    render_error("An error occurred while processing your call. Please try again later.")
  end

  # Handle conference status updates
  def conference_status
    # Set CORS headers first to ensure they're always included
    set_cors_headers
    
    # Return immediately for OPTIONS requests
    if request.method == "OPTIONS"
      return head :ok
    end
    
    # Process conference status updates using service
    begin
      # Set account for local development if needed
      if !Current.account && params[:account_id].present?
        Current.account = Account.find(params[:account_id])
      end
      
      # Use service to process conference status
      service = Voice::ConferenceStatusService.new(account: Current.account, params: params)
      service.process
    rescue => e
      # Log errors but don't affect the response
      Rails.logger.error("Error processing conference status: #{e.message[0..100]}")
    end
    
    # Always return a successful response for Twilio
    head :ok
  end

  private

  def validate_twilio_signature
    validator = Voice::TwilioValidatorService.new(
      account: Current.account,
      params: params,
      request: request
    )
    
    if !validator.valid?
      render_error('Invalid Twilio signature')
      return false
    end
    
    true
  end

  def render_error(message)
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: message)
    response.hangup
    render xml: response.to_s
  end
end
