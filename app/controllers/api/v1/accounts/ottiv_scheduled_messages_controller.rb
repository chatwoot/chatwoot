class Api::V1::Accounts::OttivScheduledMessagesController < Api::V1::Accounts::BaseController
  before_action :set_scheduled_message, only: [:show, :update, :destroy]
  before_action :check_authorization, only: [:show, :update, :destroy]

  def index
    @scheduled_messages = Current.account.ottiv_scheduled_messages
                                 .includes(:creator, :conversation, :contact)

    # Filter by conversation
    @scheduled_messages = @scheduled_messages.by_conversation(params[:conversation_id]) if params[:conversation_id].present?

    # Filter by status
    @scheduled_messages = @scheduled_messages.by_status(params[:status]) if params[:status].present?

    # Filter by creator
    @scheduled_messages = @scheduled_messages.where(created_by: params[:created_by]) if params[:created_by].present?

    # Filter pending (for scheduler to fetch)
    @scheduled_messages = @scheduled_messages.pending if params[:pending] == 'true'

    # Filter upcoming
    @scheduled_messages = @scheduled_messages.upcoming if params[:upcoming] == 'true'

    @scheduled_messages = @scheduled_messages.order(send_at: :asc)
    render json: @scheduled_messages
  end

  def show
    render json: @scheduled_message
  end

  def create
    service = OttivScheduledMessages::CreateService.new(
      params: scheduled_message_params,
      user: Current.user,
      account: Current.account
    )

    @scheduled_message = service.perform
    render json: @scheduled_message, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    # Only allow updating status (to cancel)
    if params[:ottiv_scheduled_message][:status] == 'cancelled'
      @scheduled_message.cancel!
      render json: @scheduled_message
    else
      render json: { error: 'Only status update to cancelled is allowed' }, status: :unprocessable_entity
    end
  end

  def destroy
    @scheduled_message.cancel!
    head :no_content
  end

  def send_message
    # Endpoint para o scheduler Node enviar a mensagem
    @scheduled_message = Current.account.ottiv_scheduled_messages.find(params[:id])
    
    service = OttivScheduledMessages::SendService.new(@scheduled_message)
    message = service.perform
    
    render json: { 
      success: true, 
      message: message,
      scheduled_message: @scheduled_message
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_scheduled_message
    @scheduled_message = Current.account.ottiv_scheduled_messages.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Scheduled message not found' }, status: :not_found
  end

  def check_authorization
    # User must be the creator or an admin
    unless @scheduled_message.created_by == Current.user.id || Current.user.administrator?
      render json: { error: 'Unauthorized' }, status: :forbidden
    end
  end

  def scheduled_message_params
    params.require(:ottiv_scheduled_message).permit(
      :title,
      :message_type,
      :content,
      :media_url,
      :audio_url,
      :quick_reply_id,
      :conversation_id,
      :contact_id,
      :send_at,
      :timezone,
      :recurrence
    )
  end
end

