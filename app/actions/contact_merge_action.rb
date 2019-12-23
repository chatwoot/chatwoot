class ContactMergeAction
  attr_reader :base_contact, :mergee_contact

  def initialize(params)
    @base_contact = params[:base_contact]
    @mergee_contact = params[:mergee_contact]
  end

  def perform
    ActiveRecord::Base.transaction do
      merge_conversations
      merge_contact_inboxes
      remove_mergee_contact
    end
  end

  private

  def merge_conversations
    Conversation.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def merge_contact_inboxes
    ContactInbox.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def remove_mergee_contact
    @mergee_contact.destroy!
  end
end
