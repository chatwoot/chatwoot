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
    @merged_contact_email_rows = if contact_email_rows_for(base_contact).present?
                                   merged_email_rows_preserving_base_primary
                                 else
                                   normalized_email_rows(contact_email_rows_for(mergee_contact))
                                 end
  end

  def merge_and_remove_mergee_contact
    mergable_attribute_keys = %w[identifier name phone_number additional_attributes custom_attributes]
    base_contact_attributes = base_contact.attributes.slice(*mergable_attribute_keys).compact_blank
    mergee_contact_attributes = mergee_contact.attributes.slice(*mergable_attribute_keys).compact_blank

    # attributes in base contact are given preference
    merged_attributes = mergee_contact_attributes.deep_merge(base_contact_attributes)

    @mergee_contact.reload.destroy!
    @base_contact.update!(merged_attributes) if merged_attributes.present?
    sync_merged_contact_emails!
    Rails.configuration.dispatcher.dispatch(CONTACT_MERGED, Time.zone.now, contact: @base_contact,
                                                                           tokens: [@base_contact.contact_inboxes.filter_map(&:pubsub_token)])
  end

  def sync_merged_contact_emails!
    @base_contact = Contacts::EmailAddressesSyncService.new(
      contact: @base_contact,
      email_addresses: @merged_contact_email_rows || []
    ).perform
  end

  def merged_email_rows_preserving_base_primary
    merged_rows = normalized_email_rows(contact_email_rows_for(base_contact))
    existing_emails = merged_rows.pluck(:email)

    normalized_email_rows(contact_email_rows_for(mergee_contact)).each do |row|
      next if existing_emails.include?(row[:email])

      merged_rows << row.merge(primary: false)
      existing_emails << row[:email]
    end

    merged_rows
  end

  def normalized_email_rows(rows)
    primary_email = rows.find { |row| row[:primary] }&.dig(:email) || rows.first&.dig(:email)

    rows.map do |row|
      { email: row[:email], primary: row[:email] == primary_email }
    end
  end

  def contact_email_rows_for(contact)
    rows = contact.contact_emails.order(primary: :desc, created_at: :asc, id: :asc).pluck(:email, :primary)
    return rows.map { |email, primary| { email: email, primary: primary } } if rows.present?
    return [] if contact.email.blank?

    [{ email: contact.email.strip.downcase, primary: true }]
  end
end

ContactMergeAction.prepend_mod_with('ContactMergeAction')
