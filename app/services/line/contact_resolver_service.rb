class Line::ContactResolverService
  class AmbiguousContactMatchError < StandardError; end

  pattr_initialize [:inbox!, :profile!]

  def perform
    existing_contact_inbox || contact_inbox_for_existing_contact || create_contact_inbox_with_contact
  end

  private

  def existing_contact_inbox
    @existing_contact_inbox ||= inbox.contact_inboxes.find_by(source_id: line_user_id)
  end

  def contact_inbox_for_existing_contact
    contact = find_contact_by_line_identity
    return unless contact

    enrich_contact(contact)
    ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: line_user_id).perform
  end

  def create_contact_inbox_with_contact
    ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: line_user_id,
      contact_attributes: {
        name: profile.display_name,
        avatar_url: profile.picture_url,
        additional_attributes: { social_line_user_id: line_user_id },
        custom_attributes: { line_handle: line_user_id }
      }
    ).perform
  end

  def enrich_contact(contact)
    contact.update!(
      additional_attributes: contact.additional_attributes.merge('social_line_user_id' => line_user_id),
      custom_attributes: contact.custom_attributes.merge('line_handle' => line_user_id),
      name: contact.name.presence || profile.display_name
    )
  end

  def find_contact_by_line_identity
    matches = inbox.account.contacts
                   .where(
                     "additional_attributes ->> 'social_line_user_id' = :line_user_id OR custom_attributes ->> 'line_handle' = :line_user_id",
                     line_user_id: line_user_id
                   )
                   .limit(2)
                   .to_a
    raise AmbiguousContactMatchError, line_user_id if matches.size > 1

    matches.first
  end

  def line_user_id
    profile.user_id
  end
end
