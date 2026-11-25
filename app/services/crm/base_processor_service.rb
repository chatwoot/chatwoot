class Crm::BaseProcessorService
  def initialize(hook)
    @hook = hook
    @account = hook.account
  end

  # Class method to be overridden by subclasses
  def self.crm_name
    raise NotImplementedError, 'Subclasses must define self.crm_name'
  end

  # Instance method that calls the class method
  def crm_name
    self.class.crm_name
  end

  def process_event(event_name, event_data)
    case event_name
    when 'contact.created'
      handle_contact_created(event_data)
    when 'contact.updated'
      handle_contact_updated(event_data)
    when 'conversation.created'
      handle_conversation_created(event_data)
    when 'conversation.updated'
      handle_conversation_updated(event_data)
    else
      { success: false, error: "Unsupported event: #{event_name}" }
    end
  rescue StandardError => e
    Rails.logger.error "#{crm_name} Processor Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  # Abstract methods that subclasses must implement
  def handle_contact_created(contact)
    raise NotImplementedError, 'Subclasses must implement #handle_contact_created'
  end

  def handle_contact_updated(contact)
    raise NotImplementedError, 'Subclasses must implement #handle_contact_updated'
  end

  def handle_conversation_created(conversation)
    raise NotImplementedError, 'Subclasses must implement #handle_conversation_created'
  end

  def handle_conversation_resolved(conversation)
    raise NotImplementedError, 'Subclasses must implement #handle_conversation_resolved'
  end

  # Common helper methods for all CRM processors

  protected

  def identifiable_contact?(contact)
    has_social_profile = contact.additional_attributes['social_profiles'].present?
    contact.present? && (contact.email.present? || contact.phone_number.present? || has_social_profile)
  end

  def get_external_id(contact)
    return nil if contact.additional_attributes.blank?
    return nil if contact.additional_attributes['external'].blank?

    contact.additional_attributes.dig('external', "#{crm_name}_id")
  end

  # The CRM call that produced this id was a network round trip, and the contact was read
  # before it, so the write goes in against the row as it is now. `under` keeps the siblings
  # of `external`: another CRM's id lives in that same hash.
  def store_external_id(contact, external_id)
    contact.merge_json_column!(:additional_attributes, under: 'external', merge: { "#{crm_name}_id" => external_id })
  end

  # This one runs after a network call too: the CRM rejected the id, and the contact object was
  # read before that. Writing its copy back would take the whole column with it.
  def clear_external_id(contact)
    contact.merge_json_column!(:additional_attributes, under: 'external', remove: ["#{crm_name}_id"])
  end

  # Same shape as `store_external_id`: the activity id came from the network, and the sibling
  # keys under this CRM's own hash belong to earlier activities of the same conversation.
  def store_conversation_metadata(conversation, metadata)
    conversation.merge_json_column!(:additional_attributes, under: crm_name, merge: metadata)
  end
end
