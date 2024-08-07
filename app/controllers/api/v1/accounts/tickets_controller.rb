class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
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

    @ticket.update!(status: :resolved, resolved_at: Time.current)
  end

  def add_label
    @ticket.labels << Label.find(params[:label_id])
  end

  def remove_label
    @ticket.labels.delete(Label.find(params[:label_id]))
  end

  private

  def create_or_update_labels
    @ticket.labels << find_labels(params.dig(:ticket, :labels)) if params.dig(:ticket, :labels)
  rescue ActiveRecord::RecordNotUnique
    raise CustomExceptions::Ticket, I18n.t('activerecord.errors.models.ticket.errors.already_label_assigned')
  end

  def find_labels(labels)
    return [] if labels.blank?

    labels.map { |label| current_account.labels.find_id_or_title(label[:id] || label[:title]) }.flatten
  end

  def fetch_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def fetch_ticket
    @ticket = current_account.tickets.find(params[:id])
  end

  def ticket_params
    request_params = params.require(:ticket).permit(:title, :description, :status, :assigned_to, :conversation_id)
    request_params[:conversation_id] = params.dig(:conversation, :id) if params.dig(:conversation, :id).present?
    request_params
  end
end
