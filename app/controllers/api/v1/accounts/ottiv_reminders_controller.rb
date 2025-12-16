class Api::V1::Accounts::OttivRemindersController < Api::V1::Accounts::BaseController
  def index
    # Filter reminders by current account through calendar items
    @reminders = OttivReminder.joins(:ottiv_calendar_item)
                               .where(ottiv_calendar_items: { account_id: Current.account.id })
                               .includes(:ottiv_calendar_item)

    # Filter pending (for scheduler to fetch)
    if params[:pending] == 'true'
      @reminders = @reminders.pending
    end

    @reminders = @reminders.order(notify_at: :asc)
    render json: @reminders.as_json(include: :ottiv_calendar_item)
  end

  def update
    # Find reminder and ensure it belongs to current account
    @reminder = OttivReminder.joins(:ottiv_calendar_item)
                             .where(ottiv_calendar_items: { account_id: Current.account.id })
                             .find(params[:id])
    
    if @reminder.update(reminder_params)
      render json: @reminder
    else
      render json: { errors: @reminder.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Reminder not found' }, status: :not_found
  end

  private

  def reminder_params
    params.require(:ottiv_reminder).permit(:sent)
  end
end

