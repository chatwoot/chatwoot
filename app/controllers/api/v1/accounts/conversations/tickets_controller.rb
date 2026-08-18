class Api::V1::Accounts::Conversations::TicketsController < Api::V1::Accounts::Conversations::BaseController
  before_action :fetch_ticket, only: [:show, :update]

  def show; end

  def create
    # A conversation carries at most one ticket, so a repeated create is the
    # caller asking for the ticket it already made.
    @ticket = @conversation.ticket || build_ticket
    render action: 'show'
  end

  def update
    @ticket.update!(ticket_params)
    render action: 'show'
  end

  private

  def build_ticket
    @conversation.create_ticket!(
      ticket_params.merge(account_id: Current.account.id, created_by_id: Current.user.is_a?(User) ? Current.user.id : nil)
    )
  end

  def fetch_ticket
    @ticket = @conversation.ticket
    head :not_found if @ticket.blank?
  end

  def ticket_params
    params.permit(:subject, :ticket_type, :waiting_on, :waiting_note, :due_at)
  end
end
