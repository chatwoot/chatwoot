class ContactMergeAction
  include Events::Types
  pattr_initialize [:account!, :base_contact!, :mergee_contact!]

  def perform
    # This case happens when an agent updates a contact email in dashboard,
    # while the contact also update his email via email collect box
    return @base_contact if base_contact.id == mergee_contact.id

    ActiveRecord::Base.transaction do
      validate_contacts
      merge_conversations
      merge_messages
      merge_contact_inboxes
      merge_contact_notes
      merge_contact_emails
      merge_and_remove_mergee_contact
    end
    @base_contact
  end

  private

  def validate_contacts
    return if belongs_to_account?(@base_contact) && belongs_to_account?(@mergee_contact)

    raise StandardError, 'contact does not belong to the account'
  end

  def belongs_to_account?(contact)
    @account.id == contact.account_id
  end

  def merge_conversations
    Conversation.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def merge_contact_notes
    Note.where(contact_id: @mergee_contact.id, account_id: @mergee_contact.account_id).update(contact_id: @base_contact.id)
  end

  def merge_messages
    Message.where(sender: @mergee_contact).update(sender: @base_contact)
  end

  def merge_contact_inboxes
    ContactInbox.where(contact_id: @mergee_contact.id).update(contact_id: @base_contact.id)
  end

  def merge_contact_emails
    @merged_contact_emails = merged_contact_email_values
  end

  def merge_and_remove_mergee_contact
    mergable_attribute_keys = %w[identifier name email phone_number additional_attributes custom_attributes]
    base_contact_attributes = base_contact.attributes.slice(*mergable_attribute_keys).compact_blank
    mergee_contact_attributes = mergee_contact.attributes.slice(*mergable_attribute_keys).compact_blank

    # attributes in base contact are given preference
    merged_attributes = mergee_contact_attributes.deep_merge(base_contact_attributes)
    merged_attributes['email'] ||= @merged_contact_emails.first if base_contact.email.blank?

    @mergee_contact.reload.destroy!
    @base_contact.update!(merged_attributes) if merged_attributes.present?
    sync_merged_contact_emails!
    Rails.configuration.dispatcher.dispatch(CONTACT_MERGED, Time.zone.now, contact: @base_contact,
                                                                           tokens: [@base_contact.contact_inboxes.filter_map(&:pubsub_token)])
  end

  def sync_merged_contact_emails!
    @base_contact.contact_emails.destroy_all
    additional_emails = Array(@merged_contact_emails) - [@base_contact.email]
    additional_emails.each do |email|
      @base_contact.contact_emails.create!(account: account, email: email)
    end
  end

  def merged_contact_email_values
    contact_email_values_for(base_contact) | contact_email_values_for(mergee_contact)
  end

  def contact_email_values_for(contact)
    contact.all_emails.map { |email| email.to_s.strip.downcase }.compact_blank
  end
end

ContactMergeAction.prepend_mod_with('ContactMergeAction')
