class Api::V1::Accounts::Channels::Voice::WebhooksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, :set_current_user, only: [:incoming, :conference_status]
  protect_from_forgery with: :null_session, only: [:incoming, :conference_status]
  before_action :validate_twilio_signature, only: [:incoming]
  before_action :setup_webhook_request, only: [:incoming, :conference_status]

  # Common setup for all webhook requests
  def setup_webhook_request
    set_cors_headers
    return head :ok if request.method == 'OPTIONS'

    # Set account for local development if needed
    Current.account = Account.find(params[:account_id]) if !Current.account && params[:account_id].present?
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age'] = '86400' # 24 hours
  end

  # Handle incoming calls from Twilio
  def incoming
    validate_incoming_params

    service = Voice::IncomingCallService.new(
      account: Current.account,
      params: params.to_unsafe_h.merge(host_with_port: request.host_with_port)
    )
    twiml_response = service.process

    render xml: twiml_response
  rescue StandardError => e
    Rails.logger.error("Incoming call error: #{e.message}")
    render_error("We're sorry, but we're experiencing technical difficulties. Please try your call again later.")
  end

  def conference_status
    return head :ok if params['ConferenceSid'].blank? && params['CallSid'].blank?

    process_webhook_with_service do
      service = Voice::ConferenceStatusService.new(account: Current.account, params: params)
      service.process
    end
  end

  private

  def process_webhook_with_service
    begin
      yield
    rescue StandardError => e
      Rails.logger.error("Webhook error: #{e.message}")
    end
    head :ok
  end

  def validate_incoming_params
    raise 'Missing required parameter: CallSid' if params['CallSid'].blank?
    raise 'Missing required parameter: From' if params['From'].blank?
    raise 'Missing required parameter: To' if params['To'].blank?
    raise 'Current account not set' if Current.account.nil?
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
