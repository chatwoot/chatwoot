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

  def store_external_id(contact, external_id)
    # Initialize additional_attributes if it's nil
    contact.additional_attributes = {} if contact.additional_attributes.nil?

    # Initialize external hash if it doesn't exist
    contact.additional_attributes['external'] = {} if contact.additional_attributes['external'].blank?

    # Store the external ID
    contact.additional_attributes['external']["#{crm_name}_id"] = external_id
    contact.save!
  end

  def store_conversation_metadata(conversation, metadata)
    # Initialize additional_attributes if it's nil
    conversation.additional_attributes = {} if conversation.additional_attributes.nil?

    # Initialize CRM-specific hash in additional_attributes
    conversation.additional_attributes[crm_name] = {} if conversation.additional_attributes[crm_name].blank?

    # Store the metadata
    conversation.additional_attributes[crm_name].merge!(metadata)
    conversation.save!
  end
end
