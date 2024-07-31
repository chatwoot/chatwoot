class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket, only: [:show, :update, :destroy, :assign, :resolve]
  before_action :check_authorization

  def index
    @tickets = current_account.tickets.search(params[:query])
  end

  def show
    head :not_found if @ticket.nil?
  end

  def create
    @ticket = current_account.tickets.create!(ticket_params.merge(user: current_user))
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
    @ticket = current_account.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :assigned_to)
          .merge(conversation_id: params[:conversation][:id])
  end
end
