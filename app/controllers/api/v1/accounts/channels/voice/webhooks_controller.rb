class Api::V1::Accounts::Channels::Voice::WebhooksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, :set_current_user, only: [:incoming, :conference_status, :call_status]
  protect_from_forgery with: :null_session, only: [:incoming, :conference_status, :call_status]
  before_action :validate_twilio_signature, only: [:incoming, :call_status]
  before_action :handle_options_request, only: [:incoming, :conference_status, :call_status]

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
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age'] = '86400' # 24 hours
  end

  # Handle incoming calls from Twilio
  def incoming
    # Set CORS headers first to ensure they're included
    set_cors_headers

    # Process incoming call using service
    begin
      # Ensure account is set properly
      Current.account = Account.find(params[:account_id]) if !Current.account && params[:account_id].present?

      # Validate required parameters
      validate_incoming_params

      # Process the call
      service = Voice::IncomingCallService.new(
        account: Current.account,
        params: params.to_unsafe_h.merge(host_with_port: request.host_with_port)
      )
      twiml_response = service.process

      # Return TwiML response
      render xml: twiml_response
    rescue StandardError => e
      # Log the error with detailed information
      Rails.logger.error("Incoming call error: #{e.message}")

      # Return friendly error message to caller
      render_error("We're sorry, but we're experiencing technical difficulties. Please try your call again later.")
    end
  end

  # Handle individual call status updates
  def call_status
    # Set CORS headers first to ensure they're always included
    set_cors_headers

    # Return immediately for OPTIONS requests
    return head :ok if request.method == 'OPTIONS'

    # Process call status updates
    begin
      # Set account for local development if needed
      Current.account = Account.find(params[:account_id]) if !Current.account && params[:account_id].present?

      # Find conversation by CallSid
      call_sid = params['CallSid']
      # For dial action callbacks, use DialCallStatus; fallback to CallStatus for other types
      call_status = params['DialCallStatus'] || params['CallStatus']

      if call_sid.present? && call_status.present?
        conversation = Current.account.conversations.where("additional_attributes->>'call_sid' = ?", call_sid).first

        if conversation
          # Use CallStatusManager to handle the status update
          status_manager = Voice::CallStatus::Manager.new(
            conversation: conversation,
            call_sid: call_sid,
            provider: :twilio
          )

          # Map Twilio call/dial statuses to our statuses and update
          case call_status.downcase
          when 'completed', 'busy', 'failed', 'no-answer', 'canceled'
            # Standard call status values
            if conversation.additional_attributes['call_status'] == 'ringing'
              status_manager.process_status_update('no_answer')
            else
              status_manager.process_status_update('ended')
            end
          when 'answered'
            # DialCallStatus: conference calls return 'answered' when successful
            # No action needed - call continues in conference
          else
            # Handle any other dial statuses (busy, no-answer, failed from dial action)
            if conversation.additional_attributes['call_status'] == 'ringing'
              status_manager.process_status_update('no_answer')
            else
              status_manager.process_status_update('ended')
            end
          end
        end
      end

      # Call status processed successfully
    rescue StandardError => e
      # Log errors but don't affect the response
      Rails.logger.error("Call status error: #{e.message}")
    end

    # Always return a successful response for Twilio
    head :ok
  end

  # Handle conference status updates
  def conference_status
    # Set CORS headers first to ensure they're always included
    set_cors_headers

    # Return immediately for OPTIONS requests
    return head :ok if request.method == 'OPTIONS'

    # Process conference status updates using service
    begin
      # Set account for local development if needed
      Current.account = Account.find(params[:account_id]) if !Current.account && params[:account_id].present?

      # Validate required parameters - need either ConferenceSid or CallSid
      return head :ok if params['ConferenceSid'].blank? && params['CallSid'].blank?

      # Use service to process conference status
      service = Voice::ConferenceStatusService.new(account: Current.account, params: params)
      service.process

      # Conference status processed successfully
    rescue StandardError => e
      # Log errors but don't affect the response
      Rails.logger.error("Conference status error: #{e.message}")
    end

    # Always return a successful response for Twilio
    head :ok
  end

  private

  def validate_incoming_params
    raise 'Missing required parameter: CallSid' if params['CallSid'].blank?

    raise 'Missing required parameter: From' if params['From'].blank?

    raise 'Missing required parameter: To' if params['To'].blank?

    return unless Current.account.nil?

    raise 'Current account not set'
  end

  def validate_twilio_signature
    validator = Voice::TwilioValidatorService.new(
      account: Current.account,
      params: params,
      request: request
    )

    unless validator.valid?
      render_error('Invalid Twilio signature')
      return false
    end

    return true
  rescue StandardError => e
    Rails.logger.error("Twilio validation error: #{e.message}")
    render_error('Error validating Twilio request')
    return false
  end

  def render_error(message)
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: message)
    response.hangup
    render xml: response.to_s
  end
end
