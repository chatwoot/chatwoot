class Messages::MessageBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @items = params.to_unsafe_h&.dig(:content_attributes, :items)
    @attachments = params[:attachments]
    @in_reply_to = params.to_unsafe_h&.dig(:content_attributes, :in_reply_to)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    process_attachments
    process_emails
    @message.save!
    @message
  end

  private

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      @message.attachments.build(
        account_id: @message.account_id,
        file_type: file_type(uploaded_attachment&.content_type),
        file: uploaded_attachment
      )
    end
  end

  def process_emails
    return unless @conversation.inbox&.inbox_type == 'Email'

    cc_emails = @params[:cc_emails].split(',') if @params[:cc_emails]
    bcc_emails = @params[:bcc_emails].split(',') if @params[:bcc_emails]

    @message.content_attributes[:cc_emails] = cc_emails
    @message.content_attributes[:bcc_emails] = bcc_emails
  end

  def message_type
    if @conversation.inbox.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id]
    }.merge(external_created_at)
  end
end
