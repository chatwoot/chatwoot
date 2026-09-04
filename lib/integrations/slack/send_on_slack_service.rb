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
    # You may wonder why we're not requesting reauthorization and disabling hooks when scope errors occur.
    # Since link unfurling is just a nice-to-have feature that doesn't affect core functionality, we will silently ignore these errors.
  rescue Slack::Web::Api::Errors::MissingScope => e
    Rails.logger.warn "Slack: Missing scope error: #{e.message}"
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
    text = content.present? ? content.gsub(MENTION_REGEX, '\1') : content

    [text, unattached_attachment_note].select(&:present?).join("\n")
  end

  # file_type values that never carry a downloaded file by design - their data lives entirely
  # in external_url/meta, so an attachment of one of these types is not a failed download.
  NEVER_DOWNLOADED_FILE_TYPES = %w[location fallback contact embed].freeze

  # build_files_array skips attachments whose blob failed to download, so without this
  # note an attachment-only message (no text) ends up with blank message_content and is
  # never posted to Slack at all - the customer's message becomes invisible there.
  # Deliberately broader than with_attached_file?: a share/story_mention/ig_* attachment can
  # also fail its download and end up unattached, and still needs this fallback.
  def unattached_attachment_note
    unattached = message.attachments.reject do |attachment|
      attachment.file.attached? || attachment.external_url.blank? || NEVER_DOWNLOADED_FILE_TYPES.include?(attachment.file_type)
    end
    return if unattached.blank?

    unattached.map { |attachment| "Attachment (could not be uploaded): #{attachment.external_url}" }.join("\n")
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
    upload_files if message.attachments.any?
  rescue Slack::Web::Api::Errors::IsArchived, Slack::Web::Api::Errors::AccountInactive, Slack::Web::Api::Errors::MissingScope,
         Slack::Web::Api::Errors::InvalidAuth,
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

  def upload_files
    files = build_files_array
    return if files.empty?

    begin
      result = slack_client.files_upload_v2(
        files: files,
        initial_comment: 'Attached File!',
        thread_ts: conversation.identifier,
        channel_id: hook.reference_id
      )
      Rails.logger.info "slack_upload_result: #{result}"
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error "Failed to upload files: #{e.message}"
    ensure
      files.each { |file| file[:content]&.clear }
    end
  end

  def build_files_array
    message.attachments.filter_map do |attachment|
      next unless attachment.with_attached_file?
      next unless attachment.file.attached?

      build_file_payload(attachment)
    end
  end

  def build_file_payload(attachment)
    content = download_attachment_content(attachment)
    return if content.blank?

    {
      filename: attachment.file.filename.to_s,
      content: content,
      title: attachment.file.filename.to_s
    }
  end

  def download_attachment_content(attachment)
    buffer = +''
    attachment.file.blob.open do |file|
      while (chunk = file.read(64.kilobytes))
        buffer << chunk
      end
    end
    buffer
  end

  def sender_name(sender)
    sender.try(:name) ? "#{sender.try(:name)} (#{sender_type(sender)})" : sender_type(sender)
  end

  def sender_type(sender)
    if sender.instance_of?(Contact)
      'Contact'
    elsif sender.instance_of?(User)
      'Agent'
    elsif message.message_type == 'activity' && sender.nil?
      'System'
    else
      'Bot'
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
