# frozen_string_literal: true

class Api::V1::Accounts::ScheduledMessagesController < Api::V1::Accounts::BaseController
  before_action :fetch_scheduled_message, only: [:show, :update, :destroy, :send_now]

  def index
    @scheduled_messages = if params[:conversation_id].present?
                            fetch_by_conversation
                          else
                            fetch_all
                          end

    @scheduled_messages = @scheduled_messages.includes(:sender, :conversation).order(scheduled_at: :asc)
  end

  def show; end

  def create
    # Find by display_id since that's what comes from the URL
    conversation = Current.account.conversations.find_by(display_id: scheduled_message_params[:conversation_id])

    unless conversation
      render json: { error: 'Conversation not found' }, status: :not_found
      return
    end

    @scheduled_message = Current.account.scheduled_messages.new(scheduled_message_params)
    @scheduled_message.conversation_id = conversation.id  # Use the real conversation ID
    @scheduled_message.sender = Current.user
    @scheduled_message.inbox_id = conversation.inbox_id
    @scheduled_message.account_id = Current.account.id

    authorize @scheduled_message

    if @scheduled_message.save
      render json: @scheduled_message, status: :created
    else
      render json: { errors: @scheduled_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize @scheduled_message

    if @scheduled_message.update(scheduled_message_params)
      render json: @scheduled_message
    else
      render json: { errors: @scheduled_message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scheduled_message

    if @scheduled_message.destroy
      head :ok
    else
      render json: { error: 'Cannot delete message' }, status: :unprocessable_entity
    end
  end

  def send_now
    authorize @scheduled_message

    if @scheduled_message.send_now!
      head :accepted
    else
      render json: { error: 'Cannot send message' }, status: :unprocessable_entity
    end
  end

  private

  def fetch_by_conversation
    # Find by display_id since that's what comes from the URL
    conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
    return Current.account.scheduled_messages.none unless conversation

    Current.account.scheduled_messages.by_conversation(conversation.id)
  end

  def fetch_all
    Current.account.scheduled_messages
  end

  def fetch_scheduled_message
    @scheduled_message = Current.account.scheduled_messages.find(params[:id])
  end

  def scheduled_message_params
    params.require(:scheduled_message).permit(
      :conversation_id,
      :content,
      :scheduled_at,
      :message_type,
      :content_type,
      :private,
      content_attributes: {},
      additional_attributes: {}
    )
  end
end
