class Api::V1::Accounts::Kanban::CardSchedulesController < Api::V1::Accounts::BaseController
  before_action :find_card
  before_action :find_schedule, only: [:destroy]

  def index
    @schedules = @card.schedules.pending.order(scheduled_at: :asc)
    render json: @schedules.map { |s| schedule_json(s) }
  end

  def create
    @schedule = @card.schedules.build(schedule_params)
    @schedule.created_by = current_user
    @schedule.save!
    render json: schedule_json(@schedule), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.first }, status: :unprocessable_entity
  end

  def destroy
    @schedule.cancelled!
    head :ok
  end

  private

  def find_card
    board = Current.account.kanban_boards.find_or_create_by!(user: current_user)
    @card = board.cards.find(params[:card_id])
  end

  def find_schedule
    @schedule = @card.schedules.pending.find(params[:id])
  end

  def schedule_params
    params.require(:schedule).permit(:title, :description, :scheduled_at)
  end

  def schedule_json(schedule)
    {
      id: schedule.id,
      title: schedule.title,
      description: schedule.description,
      scheduled_at: schedule.scheduled_at,
      status: schedule.status,
      created_by_name: schedule.created_by&.name
    }
  end
end
