class Api::V1::Accounts::Conversations::EmailPreviewsController < Api::V1::Accounts::BaseController
  include ::EmailHelper

  before_action :set_conversation

  def show
    authorize @conversation.inbox, :show?

    # Build a temporary message object with the current draft content
    message = build_preview_message

    # Process Liquid variables in the message content
    # This mimics what happens in MessageBuilder when a message is saved
    process_liquid_in_message_content(message)

    # Use ConversationReplyMailer to render the email without sending it
    mail = ConversationReplyMailer.email_reply(message)

    # Extract the HTML body
    html_body = if mail.html_part
                  mail.html_part.body.to_s
                else
                  mail.body.to_s
                end

    render json: { html: html_body }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
  end

  def build_preview_message
    # Create a new unsaved message with the preview content
    message = @conversation.messages.new(
      message_type: :outgoing,
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      sender: current_user,
      content: preview_params[:message]
    )

    # Add email-specific content attributes
    message.content_attributes = {
      email: {
        subject: subject_param
      },
      cc_emails: preview_params[:cc],
      bcc_emails: preview_params[:bcc],
      to_emails: preview_params[:to]
    }

    message
  end

  def process_liquid_in_message_content(message)
    return if message.content.blank?

    # Process liquid variables in the message content
    normalized_content = normalize_email_body(message.content)
    liquid_content = modified_liquid_content(normalized_content)

    template = Liquid::Template.parse(liquid_content)
    processed_content = template.render(message_drops(@conversation).merge({
                                                                             'agent' => UserDrop.new(message.sender)
                                                                           }))

    # Store processed content in content_attributes like MessageBuilder does
    message.content_attributes[:email] ||= {}
    message.content_attributes[:email][:html_content] = {
      reply: render_email_html(processed_content)
    }
  rescue Liquid::Error
    # On error, fallback to original content
    message.content_attributes[:email] ||= {}
    message.content_attributes[:email][:html_content] = {
      reply: render_email_html(message.content)
    }
  end

  def preview_params
    params.permit(:message, :cc, :bcc, :to, :subject)
  end

  def subject_param
    preview_params[:subject] || @conversation.additional_attributes['mail_subject']
  end
end
