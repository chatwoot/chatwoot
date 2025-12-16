class Api::V1::Accounts::OttivCalendarItemsController < Api::V1::Accounts::BaseController
  before_action :set_calendar_item, only: [:show, :update, :destroy, :complete, :cancel]
  before_action :check_authorization, only: [:show, :update, :destroy, :complete, :cancel]

  def index
    @calendar_items = Current.account.ottiv_calendar_items
                             .includes(:user, :ottiv_reminders, :conversation, :contacts, :participants)

    # Filter by user
    @calendar_items = @calendar_items.by_user(params[:user_id]) if params[:user_id].present?

    # Filter by item_type
    @calendar_items = @calendar_items.where(item_type: params[:item_type]) if params[:item_type].present?

    # Filter by status
    @calendar_items = @calendar_items.where(status: params[:status]) if params[:status].present?

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      start_date = Time.zone.parse(params[:start_date])
      end_date = Time.zone.parse(params[:end_date])
      @calendar_items = @calendar_items.by_date_range(start_date, end_date)
    end

    # Filter by conversation
    @calendar_items = @calendar_items.by_conversation(params[:conversation_id]) if params[:conversation_id].present?

    @calendar_items = @calendar_items.order(start_at: :asc)
    render json: @calendar_items.as_json(include: [:ottiv_reminders, :contacts, :participants])
  end

  def show
    render json: @calendar_item.as_json(include: [:ottiv_reminders, :contacts, :participants])
  end

  def create
    service = OttivCalendarItems::CreateService.new(
      params: calendar_item_params,
      user: Current.user,
      account: Current.account
    )

    @calendar_item = service.perform
    render json: @calendar_item.as_json(include: [:ottiv_reminders, :contacts, :participants]), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    if @calendar_item.update(calendar_item_params)
      render json: @calendar_item.as_json(include: [:ottiv_reminders, :contacts, :participants])
    else
      render json: { errors: @calendar_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @calendar_item.destroy!
    head :no_content
  end

  def complete
    @calendar_item.complete!
    render json: @calendar_item.as_json(include: [:ottiv_reminders, :contacts, :participants])
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def cancel
    @calendar_item.cancel!
    render json: @calendar_item.as_json(include: [:ottiv_reminders, :contacts, :participants])
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_calendar_item
    @calendar_item = Current.account.ottiv_calendar_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Calendar item not found' }, status: :not_found
  end

  def check_authorization
    # User must be the owner or an admin
    unless @calendar_item.user_id == Current.user.id || Current.user.administrator?
      render json: { error: 'Unauthorized' }, status: :forbidden
    end
  end

  def calendar_item_params
    params.require(:ottiv_calendar_item).permit(
      :item_type,
      :title,
      :description,
      :start_at,
      :end_at,
      :location,
      :status,
      :conversation_id,
      contact_ids: [],
      participant_ids: [],
      reminders: [:notify_at, :channel]
    )
  end
end

