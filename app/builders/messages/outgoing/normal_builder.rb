class Messages::Outgoing::NormalBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @content = params[:content]
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @fb_id = params[:fb_id]
    @content_type = params[:content_type]
    @items = params.to_unsafe_h&.dig(:content_attributes, :items)
    @attachments = params[:attachments]
  end

  def perform
    @message = @conversation.messages.build(message_params)
    if @attachments.present?
      @attachments.each do |uploaded_attachment|
        attachment = @message.attachments.new(
          account_id: @message.account_id,
          file_type: file_type(uploaded_attachment&.content_type)
        )
        attachment.file.attach(uploaded_attachment)
      end
    end
    @message.save
    @message
  end

  private

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: @content,
      private: @private,
      user_id: @user&.id,
      source_id: @fb_id,
      content_type: @content_type,
      items: @items
    }
  end
end
