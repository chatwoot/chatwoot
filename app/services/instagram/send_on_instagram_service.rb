class Instagram::SendOnInstagramService < Base::SendOnChannelService
  include HTTParty

  pattr_initialize [:message!]

  base_uri 'https://graph.facebook.com/v11.0/me'

  private

  delegate :additional_attributes, to: :contact

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    if message.attachments.present?
      message.attachments.each do |attachment|
        send_to_facebook_page attachment_message_params(attachment)
      end
    end

    send_to_facebook_page message_params if message.content.present?
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account, user: message.sender).capture_exception
    # TODO : handle specific errors or else page will get disconnected
    # channel.authorization_error!
  end

  def message_params
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        text: message.content
      }
    }

    merge_human_agent_tag(params)
  end

  def attachment_message_params(attachment)
    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.download_url
          }
        }
      }
    }

    merge_human_agent_tag(params)
  end

  # Deliver a message with the given payload.
  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/send-message
  def send_to_facebook_page(message_content)
    access_token = channel.page_access_token
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)
    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    # url = "https://graph.facebook.com/v11.0/me/messages?access_token=#{access_token}"

    response = HTTParty.post(
      'https://graph.facebook.com/v11.0/me/messages',
      body: message_content,
      query: query
    )

    process_response(response, message_content)
  end

  def process_response(response, message_content)
    if response.success?
      parsed_response = response.parsed_response
      handle_error('Instagram response', external_error(parsed_response), message_content) if parsed_response['error'].present?
      message.source_id = parsed_response['message_id'] if parsed_response['message_id'].present?
      message.save!

      parsed_response
    else
      handle_error('Instagram HTTP error', external_error(response), message_content)
      nil
    end
  end

  def handle_error(error_type, error_message, message_content)
    Rails.logger.error("#{error_type}: #{error_message} : #{message_content}")
    message.update(status: :failed, external_error: error_message)
  end

  def external_error(response)
    # https://developers.facebook.com/docs/instagram-api/reference/error-codes/
    error_message = response.dig('error', 'message')
    error_code = response.dig('error', 'code')

    "#{error_code} - #{error_message}"
  end

  def calculate_app_secret_proof(app_secret, access_token)
    Facebook::Messenger::Configuration::AppSecretProofCalculator.call(
      app_secret, access_token
    )
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def conversation_type
    conversation.additional_attributes['type']
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
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
end
