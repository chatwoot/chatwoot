class Integrations::Slack::SendOnSlackService < Base::SendOnChannelService
  include RegexHelper
  pattr_initialize [:message!, :hook!]

  def perform
    # overriding the base class logic since the validations are different in this case.
    # FIXME: for now we will only send messages from widget to slack
    return unless valid_channel_for_slack?
    # we don't want message loop in slack
    return if message.external_source_id_slack.present?
    # we don't want to start slack thread from agent conversation as of now
    return if invalid_message?

    perform_reply
  end

  def link_unfurl(event)
    slack_client.chat_unfurl(
      event
    )
  end

  private

  def valid_channel_for_slack?
    # slack wouldn't be an ideal interface to reply to tweets, hence disabling that case
    return false if channel.is_a?(Channel::TwitterProfile) && conversation.additional_attributes['type'] == 'tweet'

    true
  end

  def invalid_message?
    (message.outgoing? || message.template?) && conversation.identifier.blank?
  end

  def perform_reply
    send_message

    return unless @slack_message

    update_reference_id
    update_external_source_id_slack
  end

  def message_content
    private_indicator = message.private? ? 'private: ' : ''
    sanitized_content = ActionView::Base.full_sanitizer.sanitize(format_message_content)

    if conversation.identifier.present?
      "#{private_indicator}#{sanitized_content}"
    else
      "#{formatted_inbox_name}#{formatted_conversation_link}#{email_subject_line}\n#{sanitized_content}"
    end
  end

  def format_message_content
    message.message_type == 'activity' ? "_#{message_text}_" : message_text
  end

  def message_text
    content = message.processed_message_content || message.content

    if content.present?
      content.gsub(MENTION_REGEX, '\1')
    else
      content
    end
  end

  def formatted_inbox_name
    "\n*Inbox:* #{message.inbox.name} (#{message.inbox.inbox_type})\n"
  end

  def formatted_conversation_link
    "#{link_to_conversation} to view the conversation.\n"
  end

  def email_subject_line
    return '' unless message.inbox.email?

    email_payload = message.content_attributes['email']
    return "*Subject:* #{email_payload['subject']}\n\n" if email_payload.present? && email_payload['subject'].present?

    ''
  end

  def avatar_url(sender)
    sender_type = sender_type(sender).downcase
    blob_key = sender&.avatar&.attached? ? sender.avatar.blob.key : nil
    generate_url(sender_type, blob_key)
  end

  def generate_url(sender_type, blob_key)
    base_url = ENV.fetch('FRONTEND_URL', nil)
    "#{base_url}/slack_uploads?blob_key=#{blob_key}&sender_type=#{sender_type}"
  end

  def send_message
    post_message if message_content.present?
    upload_file if message.attachments.any?
  rescue Slack::Web::Api::Errors::AccountInactive, Slack::Web::Api::Errors::MissingScope, Slack::Web::Api::Errors::InvalidAuth,
         Slack::Web::Api::Errors::ChannelNotFound, Slack::Web::Api::Errors::NotInChannel => e
    Rails.logger.error e
    hook.prompt_reauthorization!
    hook.disable
  end

  def post_message
    @slack_message = slack_client.chat_postMessage(
      channel: hook.reference_id,
      text: message_content,
      username: sender_name(message.sender),
      thread_ts: conversation.identifier,
      icon_url: avatar_url(message.sender),
      unfurl_links: conversation.identifier.present?
    )
  end

  def upload_file
    return unless message.attachments.first.with_attached_file?

    result = slack_client.files_upload({
      channels: hook.reference_id,
      initial_comment: 'Attached File!',
      thread_ts: conversation.identifier
    }.merge(file_information))
    Rails.logger.info(result)
  end

  def file_type
    File.extname(message.attachments.first.download_url).strip.downcase[1..]
  end

  def file_information
    {
      filename: message.attachments.first.file.filename,
      filetype: file_type,
      content: message.attachments.first.file.download,
      title: message.attachments.first.file.filename
    }
  end

  def sender_name(sender)
    sender.try(:name) ? "#{sender.try(:name)} (#{sender_type(sender)})" : sender_type(sender)
  end

  def sender_type(sender)
    if sender.instance_of?(Contact)
      'Contact'
    elsif message.message_type == 'template' && sender.nil?
      'Bot'
    elsif message.message_type == 'activity' && sender.nil?
      'System'
    else
      'Agent'
    end
  end

  def update_reference_id
    return unless should_update_reference_id?

    conversation.update!(identifier: @slack_message['ts'])
  end

  def update_external_source_id_slack
    return unless @slack_message['message']

    message.update!(external_source_id_slack: "cw-origin-#{@slack_message['message']['ts']}")
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: hook.access_token)
  end

  def link_to_conversation
    "<#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}|Click here>"
  end

  # Determines whether the conversation identifier should be updated with the ts value.
  # The identifier should be updated in the following cases:
  # - If the conversation identifier is blank, it means a new conversation is being created.
  # - If the thread_ts is blank, it means that the conversation was previously connected in a different channel.
  def should_update_reference_id?
    conversation.identifier.blank? || @slack_message['message']['thread_ts'].blank?
  end
end
