class Api::V1::Accounts::SchedulersController < Api::V1::Accounts::BaseController
  before_action :scheduler, except: [:index, :create]
  before_action :check_authorization

  def index
    @schedulers = Current.account.schedulers.includes(:inbox)
  end

  def show
    @scheduled_messages = @scheduler.scheduled_messages.order(scheduled_at: :desc).limit(50)
  end

  def create
    @scheduler = Current.account.schedulers.create!(scheduler_params)
  end

  def update
    @scheduler.update!(scheduler_params)
  end

  def destroy
    @scheduler.destroy!
    head :ok
  end

  private

  def scheduler
    @scheduler ||= Current.account.schedulers.find_by!(display_id: params[:id])
  end

  def scheduler_params
    params.require(:scheduler).permit(:title, :message_type, :inbox_id, :description, :status, template_params: {})
  end
end
