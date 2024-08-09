class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  include Api::V2::Tickets::TicketHelper

  before_action :fetch_ticket, only: %i[show update destroy assign resolve add_label remove_label]
  before_action :create_or_update_labels, only: [:update]
  before_action :fetch_conversation, only: [:conversations]

  before_action :check_authorization

  def index
    @tickets = if current_user.administrator?
                 current_account.tickets.search(params[:query])
               else
                 current_account.tickets.assigned_to(current_user.id).search(params[:query])
               end
  end

  def conversations
    @tickets = @conversation.tickets
  end

  def show
    head :not_found if @ticket.nil?
  end

  def create
    @ticket = current_account.tickets.create!(ticket_params.merge(user: current_user))
    create_or_update_labels
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
    raise CustomExceptions::Ticket, I18n.t('activerecord.errors.models.ticket.errors.need_to_be_assigned') if @ticket.assignee.blank?

    @ticket.update!(status: :resolved, resolved_at: Time.current)
  end

  def add_label
    @ticket.labels << Label.find(params[:label_id])
  end

  def remove_label
    @ticket.labels.delete(Label.find(params[:label_id]))
  end

  private

  def fetch_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def fetch_ticket
    @ticket = current_account.tickets.find(params[:id])
  end
end
