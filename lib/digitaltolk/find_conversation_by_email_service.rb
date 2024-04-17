class Digitaltolk::FindConversationByEmailService
  attr_accessor :params, :contact

  def initialize(params)
    @params = params
  end

  def perform
    find_contact
    fetch_conversations
  end

  private

  def fetch_conversations
    return Conversation.none if @contact.blank?

    @contact.conversations.order(created_at: :desc).page(current_page).per(limit)
  end

  def find_contact
    @contact = Contact.find_by(email: email)
  end

  def email
    params[:email].to_s.strip.downcase
  end

  def limit
    params[:limit].presence || 10
  end

  def current_page
    params[:page].presence || 1
  end
end
