class Api::V1::Bot::MessagesController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, except: [:batch_create]

  # POST /api/v1/bot/messages
  # Tạo một tin nhắn mới với hiệu suất tối ưu
  def create
    @message = Bot::MessageService.new(
      conversation: @conversation,
      params: message_params,
      user: Current.user || @resource
    ).perform

    render json: @message
  end

  # POST /api/v1/bot/messages/batch_create
  # Tạo nhiều tin nhắn cùng lúc
  def batch_create
    messages = []
    ActiveRecord::Base.transaction do
      message_params[:messages].each do |message|
        conversation = Conversation.find_by(display_id: message[:conversation_id])
        next unless conversation

        new_message = Bot::MessageService.new(
          conversation: conversation,
          params: message.except(:conversation_id),
          user: Current.user || @resource
        ).perform

        messages << new_message if new_message.present?
      end
    end

    render json: messages
  end

  private

  def fetch_conversation
    @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
    render json: { error: 'Conversation not found' }, status: :not_found if @conversation.blank?
  end

  def message_params
    params.permit(
      :content,
      :private,
      :message_type,
      :content_type,
      :in_reply_to,
      attachments: [
        :file,
        :file_type,
        :external_url
      ],
      messages: [
        :conversation_id,
        :content,
        :private,
        :message_type,
        :content_type,
        :in_reply_to,
        attachments: [
          :file,
          :file_type,
          :external_url
        ]
      ]
    )
  end
end
