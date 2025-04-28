class Api::V1::Accounts::Channels::Voice::WebhooksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, :set_current_user, only: [:incoming, :conference_status]
  before_action :validate_twilio_signature, only: [:incoming]

  # Handle incoming calls from Twilio
  def incoming
    # Find the corresponding voice channel/inbox for this number
    to_number = params['To']
    inbox = Current.account.inboxes
                   .where(channel_type: 'Channel::Voice')
                   .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                   .where('channel_voice.phone_number = ?', to_number)
                   .first

    unless inbox
      render_error('Inbox not found for this phone number')
      return
    end

    # Get caller information
    from_number = params['From']
    call_sid = params['CallSid']

    # Find or create the contact
    contact = Current.account.contacts.find_or_create_by!(phone_number: from_number) do |c|
      c.name = "Contact from #{from_number}"
    end

    # Find or create the contact inbox
    contact_inbox = ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    )
    contact_inbox.update!(source_id: from_number) if contact_inbox.source_id.blank?

    # Create a new conversation for this call
    conversation = Current.account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      status: :open,
      contact: contact,
      additional_attributes: {
        'call_sid' => call_sid,
        'call_status' => 'ringing',
        'call_direction' => 'inbound'
      }
    )

    # Create an activity message for the incoming call
    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: 'Incoming call',
        message_type: :activity,
        additional_attributes: {
          call_sid: call_sid,
          call_status: 'ringing',
          call_direction: 'inbound'
        }
      }
    ).perform

    # Generate minimal TwiML response
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: 'Thank you for calling. An agent will be with you shortly.')
    response.pause(length: 2)

    # Add minimal conference with just the essential parameters
    response.dial do |dial|
      dial.conference(
        "conf_#{call_sid}",
        status_callback: "#{base_url}/api/v1/accounts/#{Current.account.id}/channels/voice/webhooks/conference_status",
        status_callback_event: 'start end join leave',
        status_callback_method: 'POST',
        end_conference_on_exit: true
      )
    end

    render xml: response.to_s
  end

  # Handle conference status updates
  def conference_status
    call_sid = params['CallSid']
    conference_sid = params['ConferenceSid']
    event = params['StatusCallbackEvent']

    # For local development, set Current.account if not set
    if Rails.env.development? && !Current.account
      account_id = params[:account_id]
      Current.account = Account.find(account_id) if account_id
    end

    # Try to find the conversation by call_sid or conference_sid
    conversation = if call_sid.present?
                     Current.account.conversations
                            .where("additional_attributes->>'call_sid' = ?", call_sid)
                            .first
                   elsif conference_sid.present?
                     Current.account.conversations
                            .where("additional_attributes->>'conference_sid' = ?", conference_sid)
                            .first
                   end

    # Return minimal error if conversation not found
    return head :not_found unless conversation

    # Update conversation with conference info
    conversation.additional_attributes ||= {}
    conversation.additional_attributes['conference_sid'] = conference_sid

    case event
    when 'conference-start'
      conversation.additional_attributes['conference_status'] = 'started'
      activity_message = 'Conference started'
    when 'conference-end'
      conversation.additional_attributes['conference_status'] = 'ended'
      conversation.additional_attributes['call_status'] = 'completed'
      conversation.additional_attributes['call_ended_at'] = Time.now.to_i
      conversation.status = :resolved
      activity_message = 'Conference ended'
    when 'participant-join'
      activity_message = 'Participant joined the call'
    when 'participant-leave'
      activity_message = 'Participant left the call'
    else
      activity_message = 'Call event occurred'
    end

    conversation.save!

    # Create activity message with minimal attributes
    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: activity_message,
        message_type: :activity,
        additional_attributes: {
          call_sid: call_sid,
          event_type: event
        }
      }
    ).perform

    # Broadcast minimal update to frontend
    ActionCable.server.broadcast(
      "#{conversation.account_id}_#{conversation.inbox_id}",
      {
        event_name: 'call_status_changed',
        data: {
          call_sid: call_sid,
          status: conversation.additional_attributes['call_status'] || 'in-progress',
          conversation_id: conversation.id
        }
      }
    )

    # Return minimal response
    head :ok
  end

  private

  def validate_twilio_signature
    # Find the inbox for the phone number
    to_number = params['To']

    # Skip validation for local development
    return true if Rails.env.development?

    inbox = Current.account.inboxes
                   .where(channel_type: 'Channel::Voice')
                   .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                   .where('channel_voice.phone_number = ?', to_number)
                   .first

    return render_error('Inbox not found for this phone number') unless inbox

    # Get Twilio Auth Token from inbox's channel
    channel = inbox.channel
    return render_error('Channel is not a voice channel') unless channel.is_a?(Channel::Voice)

    auth_token = channel.provider_config_hash['auth_token']

    # Validate incoming request signature
    validator = Twilio::Security::RequestValidator.new(auth_token)
    signature = request.headers['X-Twilio-Signature']

    # Check if incoming signature is valid
    url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    is_valid = validator.validate(url, params.to_unsafe_h, signature)

    unless is_valid
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

  def base_url
    ENV.fetch('FRONTEND_URL', "https://#{request.host_with_port}")
  end
end
