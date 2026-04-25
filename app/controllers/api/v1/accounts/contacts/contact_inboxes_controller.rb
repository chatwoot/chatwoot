class Api::V1::Accounts::Contacts::ContactInboxesController < Api::V1::Accounts::Contacts::BaseController
  include HmacConcern
  before_action :ensure_inbox, only: [:create]

 # respects the inbox reopen setting
def create
  conversation = find_or_create_conversation
  render json: conversation
end

private

def find_or_create_conversation
  inbox = current_account.inboxes.find(conversation_params[:inbox_id])

  # Only attempt to reuse for WhatsApp inboxes with reopen setting enabled
  if inbox.channel_type == 'Channel::Whatsapp' && inbox.lock_to_single_conversation
    existing = most_recent_resolvable_conversation(inbox)
    if existing
      existing.reopen!
      return existing
    end
  end

  ConversationBuilder.new(params: conversation_params, account: current_account).perform
end

def most_recent_resolvable_conversation(inbox)
  contact = current_account.contacts.find(conversation_params[:contact_id])
  contact.conversations
         .where(inbox: inbox)
         .where(status: :resolved)
         .order(last_activity_at: :desc)
         .first
end

  private

  def ensure_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end
end
