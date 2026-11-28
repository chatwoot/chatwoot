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
      merge_calls
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

  def merge_calls
    # overridden in enterprise/app/actions/enterprise/contact_merge_action.rb
  end

  def merge_and_remove_mergee_contact
    mergable_attribute_keys = %w[identifier name email phone_number additional_attributes custom_attributes]
    base_contact_attributes = base_contact.attributes.slice(*mergable_attribute_keys).compact_blank
    mergee_contact_attributes = mergee_contact.attributes.slice(*mergable_attribute_keys).compact_blank

    # attributes in base contact are given preference
    merged_attributes = mergee_contact_attributes.deep_merge(base_contact_attributes)
    merged_attributes['contact_type'] = higher_contact_type
    verified_mergee_values = verified_values_only_on_mergee

    @mergee_contact.reload.destroy!
    Rails.configuration.dispatcher.dispatch(CONTACT_MERGED, Time.zone.now, contact: @base_contact)
    @base_contact.assign_attributes(merged_attributes)
    verified_mergee_values.each do |source, values|
      @base_contact.assign_verified_attributes(values, source: source)
    end
    @base_contact.save!
  end

  # A verified value of the mergee contact replaces an unverified value of the base contact.
  # Returns the values grouped by the source that verified them.
  def verified_values_only_on_mergee
    mergee_contact.verified_attributes.each_with_object({}) do |(attribute, source), values_by_source|
      next if base_contact.attribute_verified?(attribute)

      values_by_source[source] ||= {}
      values_by_source[source][attribute] = mergee_contact[attribute]
    end
  end

  def higher_contact_type
    [base_contact, mergee_contact].map(&:contact_type).max_by { |type| Contact.contact_types[type] }
  end
end

ContactMergeAction.prepend_mod_with('ContactMergeAction')
