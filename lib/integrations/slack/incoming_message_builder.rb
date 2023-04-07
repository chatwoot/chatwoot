class Integrations::Slack::IncomingMessageBuilder
  attr_reader :params

  SUPPORTED_EVENT_TYPES = %w[event_callback url_verification].freeze
  SUPPORTED_EVENTS = %w[message].freeze
  SUPPORTED_MESSAGE_TYPES = %w[rich_text].freeze

  def initialize(params)
    @params = params
  end

  def perform
    return unless valid_event?

    if hook_verification?
      verify_hook
    elsif create_message?
      create_message
    end
  end

  private

  def valid_event?
    supported_event_type? && supported_event? && should_process_event?
  end

  def supported_event_type?
    SUPPORTED_EVENT_TYPES.include?(params[:type])
  end

  # Discard all the subtype of a message event
  # We are only considering the actual message sent by a Slack user
  # Any reactions or messages sent by the bot will be ignored.
  # https://api.slack.com/events/message#subtypes
  def should_process_event?
    return true if params[:type] != 'event_callback'

    params[:event][:user].present? && params[:event][:subtype].blank?
  end

  def supported_event?
    hook_verification? || SUPPORTED_EVENTS.include?(params[:event][:type])
  end

  def supported_message?
    if message.present?
      SUPPORTED_MESSAGE_TYPES.include?(message[:type]) && !attached_file_message?
    else
      params[:event][:files].present? && !attached_file_message?
    end
  end

  def hook_verification?
    params[:type] == 'url_verification'
  end

  def thread_timestamp_available?
    params[:event][:thread_ts].present?
  end

  def create_message?
    thread_timestamp_available? && supported_message? && integration_hook
  end

  def message
    params[:event][:blocks]&.first
  end

  def verify_hook
    {
      challenge: params[:challenge]
    }
  end

  def integration_hook
    @integration_hook ||= Integrations::Hook.find_by(reference_id: params[:event][:channel])
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def sender
    user_email = slack_client.users_info(user: params[:event][:user])[:user][:profile][:email]
    conversation.account.users.find_by(email: user_email)
  end

  def private_note?
    params[:event][:text].strip.downcase.starts_with?('note:', 'private:')
  end

  def create_message
    return unless conversation

    @message = conversation.messages.create!(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: Slack::Messages::Formatting.unescape(params[:event][:text] || ''),
      external_source_id_slack: params[:event][:ts],
      private: private_note?,
      sender: sender
    )

    process_attachments(params[:event][:files]) if params[:event][:files].present?

    { status: 'success' }
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: @integration_hook.access_token)
  end

  # TODO: move process attachment for facebook instagram and slack in one place
  # https://api.slack.com/messaging/files
  def process_attachments(attachments)
    attachments.each do |attachment|
      tempfile = Down::NetHttp.download(attachment[:url_private], headers: { 'Authorization' => "Bearer #{integration_hook.access_token}" })

      attachment_params = {
        file_type: file_type(attachment),
        account_id: @message.account_id,
        external_url: attachment[:url_private],
        file: {
          io: tempfile,
          filename: tempfile.original_filename,
          content_type: tempfile.content_type
        }
      }

      attachment_obj = @message.attachments.new(attachment_params)
      attachment_obj.file.content_type = attachment[:mimetype]
      attachment_obj.save!
    end
  end

  def file_type(attachment)
    return if attachment[:mimetype] == 'text/plain'

    case attachment[:filetype]
    when 'png', 'jpeg', 'gif', 'bmp', 'tiff', 'jpg'
      :image
    when 'pdf'
      :file
    end
  end

  # Ignoring the changes added here https://github.com/chatwoot/chatwoot/blob/5b5a6d89c0cf7f3148a1439d6fcd847784a79b94/lib/integrations/slack/send_on_slack_service.rb#L69
  # This make sure 'Attached File!' comment is not visible on CW dashboard.
  # This is showing because of https://github.com/chatwoot/chatwoot/pull/4494/commits/07a1c0da1e522d76e37b5f0cecdb4613389ab9b6 change.
  # As now we consider the postback message with event[:files]
  def attached_file_message?
    params[:event][:text] == 'Attached File!'
  end
end
