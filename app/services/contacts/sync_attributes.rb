class Contacts::SyncAttributes
  attr_reader :contact

  def initialize(contact)
    @contact = contact
  end

  def perform
    update_contact_location_and_country_code
    set_contact_type
  end

  private

  def update_contact_location_and_country_code
    # Ensure that location and country_code are updated from additional_attributes.
    # TODO: Remove this once all contacts are updated and both the location and country_code fields are standardized throughout the app.
    @contact.location = @contact.additional_attributes['city']
    @contact.country_code = @contact.additional_attributes['country']
  end

  def set_contact_type
    # If the contact has an email or phone number then it is a lead
    # If contact is from external channel like facebook, instagram, whatsapp, etc then it is a lead
    return unless @contact.email.present? || @contact.phone_number.present? || social_channel?

    @contact.contact_type = 'lead'
  end

  def social_channel?
    return false if @contact.contact_inboxes.blank?

    @contact.contact_inboxes.each do |contact_inbox|
      return true if contact_inbox.inbox.facebook? || contact_inbox.inbox.instagram? || contact_inbox.inbox.telegram? || contact_inbox.inbox.line?
    end
  end
end
