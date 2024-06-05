class Api::V1::Accounts::MessagesController < Api::V1::Accounts::BaseController
  def create
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    ActiveRecord::Base.transaction do
      @contact_inbox = ContactInboxWithContactBuilder.new(inbox: inbox, contact_attributes: contact_params).perform
      @conversation = ConversationBuilder.new(params: params, contact_inbox: @contact_inbox).perform
      user = Current.user || @resource
      Messages::MessageBuilder.new(user, @conversation, params[:message]).perform
    rescue StandardError => e
      render_could_not_create_error(e.message)
    end
  end

  private

  def contact_params
    params.permit(:name, :identifier, :email, :phone_number, additional_attributes: {}, custom_attributes: {})
  end

  def find_contact
    contacts = Current.account.contacts
    contact = contacts.find_by(identifier: contact_params[:identifier])
    contact ||= contacts.from_email(contact_params[:email])
    contact ||= contacts.find_by(phone_number: contact_params[:phone_number])
    contact
  end

  def create_contact
    contact = Current.account.contacts.new(contact_params)
    contact.save!
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: inbox,
      source_id: params[:source_id]
    ).perform
  end
end
