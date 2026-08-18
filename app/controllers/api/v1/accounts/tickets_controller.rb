class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  # Params that map straight onto a column of the ticket or of its conversation.
  TICKET_FILTERS = %i[waiting_on ticket_type].freeze
  CONVERSATION_FILTERS = %i[assignee_id team_id contact_id].freeze

  def index
    @tickets = filtered_tickets.order(created_at: :desc).page(params[:page]).per(RESULTS_PER_PAGE)
  end

  private

  def filtered_tickets
    scope = Ticket.where(account_id: Current.account.id)
                  .joins(:conversation)
                  .preload(:ticket_tasks, conversation: [:assignee, :team])
    scope = apply_status_category(scope)
    scope = apply_settled(scope)
    scope = apply_attribute_filters(scope)
    apply_overdue(scope)
  end

  def apply_status_category(scope)
    return scope if params[:status_category].blank?

    scope.merge(Ticket.with_status_category(params[:status_category]))
  end

  # `settled=false` is how a caller asks for everything still on the team's
  # plate without naming one status category at a time.
  def apply_settled(scope)
    return scope unless params[:settled] == 'false'

    scope.merge(Ticket.unsettled)
  end

  def apply_attribute_filters(scope)
    TICKET_FILTERS.each do |key|
      scope = scope.where(key => params[key]) if params[key].present?
    end
    CONVERSATION_FILTERS.each do |key|
      scope = scope.where(conversations: { key => params[key] }) if params[key].present?
    end
    scope
  end

  def apply_overdue(scope)
    return scope unless ActiveModel::Type::Boolean.new.cast(params[:overdue])

    scope.where('tickets.due_at < ?', Time.current).merge(Ticket.unsettled)
  end
end
