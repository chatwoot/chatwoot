class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket, only: [:show, :update, :destroy]
  before_action :check_authorization
  before_action :find_tickets, only: [:index]

  def index
    @tickets = @user.tickets
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
    @ticket.assignee = current_user
    @ticket.save!
  end

  def resolve
    @ticket.update!(status: :resolved)
  end

  private

  def fetch_ticket
    @ticket = current_user.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :assignee_ids)
  end

  def find_tickets
    @tickets = current_user.tickets.search(params)
  end
end
