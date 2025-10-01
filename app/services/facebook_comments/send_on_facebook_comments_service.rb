class FacebookComments::SendOnFacebookCommentsService < Base::SendOnChannelService
  include HTTParty

  pattr_initialize [:message!]

  base_uri 'https://graph.facebook.com/v23.0/me'

  private

  # Delegates additional_attributes to contact (which is now correctly fetched)
  delegate :additional_attributes, to: :contact

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    send_to_facebook_page attachment_message_params if message.attachments.present?
    send_to_facebook_page message_params
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account, user: message.sender).capture_exception
    # TODO: handle specific errors or else page will get disconnected
    # channel.authorization_error!
  end

  def message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content
      }
    }.tap { |params| merge_human_agent_tag(params) }
  end

  def attachment_message_params
    attachment = message.attachments.first
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }.tap { |params| merge_human_agent_tag(params) }
  end

  def send_to_facebook_page(message_content)
    access_token = channel.page_access_token
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)

    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    url = build_facebook_url(conversation.additional_attributes['comment_id'])
    response = post_to_facebook(url, message_content[:message][:text], query)
    handle_response(response, message_content, message)
    response
  end

  def build_facebook_url(comment_id)
    "https://graph.facebook.com/v23.0/#{comment_id}/comments"
  end

  def post_to_facebook(url, message_text, query)
    HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: query,
      body: { message: message_text }.to_json
    )
  end

  def handle_response(response, message_content, message)
    if response['error'].present?
      Rails.logger.error("❌ Facebook Comment API error: #{response['error']} | Params: #{message_content}")
      message.status = :failed
      message.external_error = external_error(response)
    else
      message.source_id = response['id'] || response['message_id'] if response['id'].present? || response['message_id'].present?
    end
    message.save!
  end

  def external_error(response)
    error_message = response['error']['message']
    error_code = response['error']['code']
    "#{error_code} - #{error_message}"
  end

  def calculate_app_secret_proof(app_secret, access_token)
    Facebook::Messenger::Configuration::AppSecretProofCalculator.call(app_secret, access_token)
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include?(attachment.file_type)
    'file'
  end

  def conversation_type
    conversation.additional_attributes['type']
  end

  def sent_first_outgoing_message_after_24_hours?
    # Facebook allows 1 message after 24-hour window
    conversation.messages.outgoing.where('id > ?', conversation.last_incoming_message.id).count == 1
  end

  def config
    Facebook::Messenger.config
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
    return params unless global_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']

    params[:messaging_type] = 'MESSAGE_TAG'
    params[:tag] = 'HUMAN_AGENT'
    params
  end

  # ✅ Correctly fetch contact via conversation
  def contact
    @contact ||= begin
      conv = message.conversation
      raise "❌ Conversation not found for message ID #{message.id}" unless conv
      raise "❌ Contact not found for conversation ID #{conv.id}" unless conv.contact
      conv.contact
    end
  end

  # ✅ Safely fetch inbox from message
  def inbox
    @inbox ||= begin
      raise "❌ Inbox not found for message ID #{message.id}" unless message.inbox
      message.inbox
    end
  end

  # ✅ Safely fetch channel from inbox
  def channel
    @channel ||= inbox.channel
  end

  # ✅ Safely fetch conversation from message
  def conversation
    @conversation ||= begin
      raise "❌ Conversation not found for message ID #{message.id}" unless message.conversation
      message.conversation
    end
  end
end
