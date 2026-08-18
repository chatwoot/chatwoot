# Pre-call context for the Pathors voice platform: who is calling and what the
# team still owes them, in both structured and LLM-ready form.
class Api::V1::Accounts::Pathors::ContextsController < Api::V1::Accounts::BaseController
  OPEN_TICKETS_LIMIT = 20
  RECENT_CONVERSATIONS_LIMIT = 3

  before_action :fetch_contact

  def show
    render json: {
      contact: @contact.push_event_data,
      open_tickets: open_tickets.map(&:push_event_data),
      recent_conversations: recent_conversations.map do |conversation|
        { id: conversation.display_id, status: conversation.status, last_activity_at: conversation.last_activity_at.iso8601 }
      end,
      llm_context: llm_context
    }, status: :ok
  end

  private

  def fetch_contact
    return render json: { error: 'phone_or_contact_id_required' }, status: :bad_request if params[:phone].blank? && params[:contact_id].blank?

    @contact = find_contact
    render json: { error: 'contact_not_found' }, status: :not_found if @contact.blank?
  end

  def find_contact
    return Current.account.contacts.find_by(id: params[:contact_id]) if params[:contact_id].present?

    Current.account.contacts.find_by(phone_number: params[:phone])
  end

  def open_tickets
    @open_tickets ||= Ticket.unsettled
                            .includes(:conversation, :ticket_tasks)
                            .where(account_id: Current.account.id, conversations: { contact_id: @contact.id })
                            .order(Arel.sql('tickets.due_at ASC NULLS LAST'))
                            .limit(OPEN_TICKETS_LIMIT)
  end

  def recent_conversations
    @recent_conversations ||= @contact.conversations.order(last_activity_at: :desc).limit(RECENT_CONVERSATIONS_LIMIT)
  end

  def llm_context
    sections = [@contact.to_llm_text, 'Open Tickets:']
    sections << (open_tickets.any? ? open_tickets.map { |ticket| ticket_line(ticket) }.join("\n") : 'No open tickets for this contact')
    sections << 'Recent Conversations:'
    sections << recent_conversations_line
    sections.join("\n")
  end

  def ticket_line(ticket)
    " - ##{ticket.conversation.display_id} #{ticket.subject} | Status: #{ticket.status_category} | " \
      "Waiting On: #{ticket.waiting_on} | Due: #{ticket.due_at&.iso8601 || 'none'}"
  end

  def recent_conversations_line
    return 'No conversations for this contact' if recent_conversations.empty?

    recent_conversations.map { |conversation| "##{conversation.display_id} (#{conversation.status})" }.join(', ')
  end
end
