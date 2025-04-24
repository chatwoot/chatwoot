class Bot::MessageService
  def initialize(conversation:, params:, user:)
    @conversation = conversation
    @params = params
    @user = user
    @account = conversation.account
    @inbox = conversation.inbox
  end
  
  def perform
    ActiveRecord::Base.transaction do
      # Tạo message
      @message = build_message
      
      # Xử lý attachments
      process_attachments if @params[:attachments].present?
      
      # Lưu message
      @message.save!
    end
    
    # Gửi tin nhắn bất đồng bộ
    SendReplyJob.perform_later(@message.id) if @message.outgoing?
    
    @message
  end
  
  private
  
  def build_message
    @conversation.messages.build(
      account_id: @account.id,
      inbox_id: @inbox.id,
      message_type: @params[:message_type] || 'outgoing',
      content: @params[:content],
      content_type: @params[:content_type] || 'text',
      private: @params[:private] || false,
      sender: @user,
      content_attributes: {
        in_reply_to: @params[:in_reply_to]
      }
    )
  end
  
  def process_attachments
    @params[:attachments].each do |attachment|
      if attachment[:external_url].present?
        # Ưu tiên sử dụng external_url
        @message.attachments.build(
          account_id: @account.id,
          file_type: attachment[:file_type] || :image,
          external_url: attachment[:external_url]
        )
      elsif attachment[:file].present?
        # Fallback to file upload
        @message.attachments.build(
          account_id: @account.id,
          file: attachment[:file]
        )
      end
    end
  end
end
