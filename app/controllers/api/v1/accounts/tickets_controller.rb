class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket, only: [:show, :update, :destroy, :assign, :resolve]
  before_action :check_authorization

  def index
    @tickets = current_user.tickets.search(params[:query])
  end

  def show
    head :not_found if @ticket.nil?
  end

  def create
    @ticket = @user.tickets.create!(ticket_params)
  end

  def update
    @ticket.update!(ticket_params)
  end

  def destroy
    @ticket.destroy!
    head :ok
  end

  def assign
    @ticket.assignee = User.find(params[:user_id]) || current_user
    @ticket.save!
  end

  def resolve
    raise CustomExceptions::Ticket, I18n.t('activerecord.errors.models.ticket.errors.already_resolved') if @ticket.resolved?

    @ticket.update!(status: :resolved)
  end

  private

  def fetch_ticket
    @ticket = current_user.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :assigned_to)
          .merge(conversation_id: params[:conversation][:id])
  end
end
