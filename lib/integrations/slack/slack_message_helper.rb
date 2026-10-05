module Integrations::Slack::SlackMessageHelper
  def process_message_payload
    return unless conversation

    handle_conversation
    success_response
  rescue Slack::Web::Api::Errors::MissingScope => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    disable_and_reauthorize
  end

  def handle_conversation
    return if message_exists?
    # Private notes never reach the customer, so they need no takeover.
    return takeover.request_confirmation if takeover.confirmation_required? && !private_note?

    takeover.perform(slack_sender.first) if takeover.confirmed?
    create_message
  end

  def takeover
    @takeover ||= Integrations::Slack::ConversationTakeover.new(
      conversation: conversation, params: params, slack_client: slack_client
    )
  end

  def success_response
    { status: 'success' }
  end

  def disable_and_reauthorize
    integration_hook.prompt_reauthorization!
    integration_hook.disable
  end

  def message_exists?
    conversation.messages.exists?(external_source_ids: { slack: params[:event][:ts] })
  end

  def slack_sender
    @slack_sender ||= Integrations::Slack::SenderResolver.new(
      slack_client: slack_client, account: conversation.account, slack_user_id: params[:event][:user]
    ).perform
  end

  def create_message
    resolved_sender, sender_name, sender_avatar_url = slack_sender
    slack_sender_attrs = {}
    slack_sender_attrs[:sender_name] = sender_name if sender_name
    slack_sender_attrs[:sender_avatar_url] = sender_avatar_url if sender_avatar_url
    @message = conversation.messages.build(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: formatted_message_content,
      external_source_id_slack: params[:event][:ts],
      private: private_note?,
      sender: resolved_sender,
      additional_attributes: slack_sender_attrs
    )
    process_attachments(params[:event][:files]) if attachments_present?
    @message.save!
  end

  def attachments_present?
    params[:event][:files].present?
  end

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
    end
  end

  def file_type(attachment)
    return if attachment[:mimetype] == 'text/plain'

    case attachment[:filetype]
    when 'png', 'jpeg', 'gif', 'bmp', 'tiff', 'jpg'
      :image
    when 'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'
      :video
    else
      :file
    end
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def formatted_message_content
    text = Slack::Messages::Formatting.unescape(params[:event][:text] || '')
    Integrations::Slack::EmojiFormatter.format(text)
  end

  def private_note?
    params[:event][:text].strip.downcase.starts_with?('note:', 'private:')
  end
end
