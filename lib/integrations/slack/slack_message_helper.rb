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
    create_message unless message_exists?
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

  def create_message
    resolved_sender, sender_name, sender_avatar_url = resolve_slack_sender
    slack_sender_attrs = {}
    slack_sender_attrs[:sender_name] = sender_name if sender_name
    slack_sender_attrs[:sender_avatar_url] = sender_avatar_url if sender_avatar_url
    @message = conversation.messages.build(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: Slack::Messages::Formatting.unescape(params[:event][:text] || ''),
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

  def resolve_slack_sender
    return [nil, nil, nil] unless params[:event][:user]

    slack_user = slack_client.users_info(user: params[:event][:user])[:user]
    chatwoot_user = conversation.account.users.from_email(slack_user[:profile][:email])
    return [chatwoot_user, nil, nil] if chatwoot_user

    sender_name = slack_user.dig(:profile, :display_name).presence ||
                  slack_user[:real_name].presence ||
                  slack_user[:name]
    sender_avatar_url = slack_user.dig(:profile, :image_192).presence
    [nil, sender_name, sender_avatar_url]
  rescue Slack::Web::Api::Errors::MissingScope
    raise
  rescue StandardError
    [nil, nil, nil]
  end

  def private_note?
    params[:event][:text].strip.downcase.starts_with?('note:', 'private:')
  end
end
