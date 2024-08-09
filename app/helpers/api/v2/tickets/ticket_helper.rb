module Api::V2::Tickets::TicketHelper
  def build_ticket
    ActiveRecord::Base.transaction do
      ticket = Ticket.new(ticket_params)
      create_or_update_labels(ticket)
      ticket.save!
      ticket
    end
  end

  def update_ticket(ticket)
    ActiveRecord::Base.transaction do
      create_or_update_labels(ticket)
      ticket.update!(ticket_params)
      ticket
    end
  end

  def find_labels(labels)
    return [] if labels.blank?

    labels.map { |label| current_account.labels.find_id_or_title(label[:id] || label[:title]) }.flatten
  end

  def create_or_update_labels(ticket)
    ticket.labels << find_labels(params.dig(:ticket, :labels)) if params.dig(:ticket, :labels)
  rescue ActiveRecord::RecordNotUnique
    raise CustomExceptions::Ticket, I18n.t('activerecord.errors.models.ticket.errors.already_label_assigned')
  end

  def ticket_params
    request_params = params.require(:ticket).permit(:title, :description, :status,
                                                    :assigned_to, :conversation_id,
                                                    :account_id, :user_id, :resolved_at)
    request_params[:conversation_id] = params.dig(:conversation, :id) if params.dig(:conversation, :id).present?
    request_params
  end
end
