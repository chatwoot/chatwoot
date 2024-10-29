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
    @message = conversation.messages.build(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: Slack::Messages::Formatting.unescape(params[:event][:text] || ''),
      external_source_id_slack: params[:event][:ts],
      private: private_note?,
      sender: sender
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
    when 'pdf'
      :file
    end
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def sender
    user_email = slack_client.users_info(user: params[:event][:user])[:user][:profile][:email]
    conversation.account.users.from_email(user_email)
  end

  def private_note?
    params[:event][:text].strip.downcase.starts_with?('note:', 'private:')
  end
end
