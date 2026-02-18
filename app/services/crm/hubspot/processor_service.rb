# frozen_string_literal: true

# HubSpot CRM Processor Service
#
# Dispatches CRM Flow actions to HubSpot API.
# HubSpot uses "Contacts" instead of "Leads" and "Deals" instead of "Opportunities".
class Crm::Hubspot::ProcessorService < Crm::BaseProcessorService
  def initialize(hook)
    super(hook)
    @contact_client  = Crm::Hubspot::Api::ContactClient.new(hook)
    @activity_client = Crm::Hubspot::Api::ActivityClient.new(hook)
  end

  def self.crm_name
    'hubspot'
  end

  def execute_action(action_type, params = {})
    case action_type.to_s
    when 'create_lead'        then create_lead(params)
    when 'create_contact'     then create_contact(params)
    when 'create_opportunity' then create_opportunity(params)
    when 'create_task'        then create_task(params)
    when 'create_event'       then create_event(params)
    when 'add_note'           then add_note(params)
    else { success: false, error: "Unknown action type: #{action_type}" }
    end
  end

  def authenticated?
    @hook.credentials['access_token'].present?
  end

  # ============================================================================
  # PROFILE SYNC
  # ============================================================================

  # Sync contact profile from HubSpot to Nauto Console Contact
  #
  # Note: HubSpot only has "Contacts" (no separate Lead object)
  # This method determines which external_id to use based on contact_type:
  # - lead: uses hubspot_lead_id
  # - customer: uses hubspot_contact_id
  #
  # @param contact [Contact] The contact to sync
  # @return [Hash] Result with success status and synced fields
  def sync_profile(contact)
    # Determine which external_id key to use based on contact_type
    external_id_key = contact.contact_type == 'customer' ? 'hubspot_contact_id' : 'hubspot_lead_id'
    external_id = get_external_id(contact, external_id_key)
    return { success: false, error: "No external_id found for #{contact.contact_type} contact" } unless external_id

    # Fetch contact profile from HubSpot
    profile = @contact_client.get_contact(external_id)
    return { success: false, error: 'Contact not found in HubSpot' } unless profile && profile['id'].present?

    # Map CRM profile to Contact attributes
    mapped_attrs = Crm::Hubspot::Mappers::ProfileMapper.map_to_contact_attributes(profile)

    # Merge additional_attributes instead of replacing
    if mapped_attrs[:additional_attributes].present?
      contact.additional_attributes ||= {}
      contact.additional_attributes.deep_merge!(mapped_attrs[:additional_attributes])
      mapped_attrs.delete(:additional_attributes)
    end

    # Update contact with mapped attributes
    contact.update!(mapped_attrs.merge(additional_attributes: contact.additional_attributes))

    Rails.logger.info "Profile synced from HubSpot for #{contact.contact_type} contact #{contact.id}"
    { success: true, synced_fields: mapped_attrs.keys }
  rescue StandardError => e
    Rails.logger.error "Error syncing profile from HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # LEAD (CONTACT) OPERATIONS
  # ============================================================================

  def create_lead(params)
    contact = find_contact_from_params(params)
    return { success: false, error: 'Contact not found' } unless contact

    # Already synced?
    external_id = contact.additional_attributes&.dig('external', 'hubspot_lead_id')
    if external_id.present?
      Rails.logger.info "Contact already synced to HubSpot: #{external_id}"
      return { success: true, lead_id: external_id, action: 'existing' }
    end

    mapper = Crm::Hubspot::Mappers::ContactMapper.new(contact)
    payload = mapper.map_to_contact(custom_fields: params[:lead_custom_fields] || {})

    response = @contact_client.create_contact(payload)

    # 409 duplicate: contact_client returns { 'duplicate' => true, 'id' => '...' }
    if response && response['duplicate']
      hubspot_id = response['id']
      store_external_id(contact, hubspot_id)
      Rails.logger.info "Contact already exists in HubSpot (409): #{hubspot_id}"
      return { success: true, lead_id: hubspot_id, action: 'duplicate' }
    end

    if response && response['id'].present?
      hubspot_id = response['id'].to_s
      store_external_id(contact, hubspot_id)
      Rails.logger.info "Contact created in HubSpot: #{hubspot_id}"
      { success: true, lead_id: hubspot_id, action: 'created' }
    else
      { success: false, error: 'Failed to create contact', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating contact in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # Create contact in HubSpot (for customers)
  #
  # Note: HubSpot only has "Contacts" (no separate Lead object)
  # This method is similar to create_lead but stores external_id with 'hubspot_contact_id' key
  #
  # @param params [Hash] Contact parameters
  # @return [Hash] Result with success status and contact_id
  def create_contact(params)
    contact = find_contact_from_params(params)
    return { success: false, error: 'Contact not found' } unless contact

    # Already synced?
    external_id = contact.additional_attributes&.dig('external', 'hubspot_contact_id')
    if external_id.present?
      Rails.logger.info "Contact (customer) already synced to HubSpot: #{external_id}"
      return { success: true, contact_id: external_id, action: 'existing' }
    end

    mapper = Crm::Hubspot::Mappers::ContactMapper.new(contact)
    payload = mapper.map_to_contact(custom_fields: params[:contact_custom_fields] || {})

    response = @contact_client.create_contact(payload)

    # 409 duplicate: contact_client returns { 'duplicate' => true, 'id' => '...' }
    if response && response['duplicate']
      hubspot_id = response['id']
      store_external_id(contact, hubspot_id, 'hubspot_contact_id')
      Rails.logger.info "Contact (customer) already exists in HubSpot (409): #{hubspot_id}"
      return { success: true, contact_id: hubspot_id, action: 'duplicate' }
    end

    if response && response['id'].present?
      hubspot_id = response['id'].to_s
      store_external_id(contact, hubspot_id, 'hubspot_contact_id')
      Rails.logger.info "Contact (customer) created in HubSpot: #{hubspot_id}"
      { success: true, contact_id: hubspot_id, action: 'created' }
    else
      { success: false, error: 'Failed to create contact', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating contact (customer) in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # OPPORTUNITY (DEAL) OPERATIONS
  # ============================================================================

  def create_opportunity(params)
    contact = find_contact_from_params(params)
    hubspot_contact_id = contact&.additional_attributes&.dig('external', 'hubspot_lead_id')

    deal_payload = Crm::Hubspot::Mappers::ActivityMapper.map_deal(
      name: params[:name] || "Deal for #{contact&.name}",
      amount: params[:amount],
      close_date: params[:close_date],
      stage: params[:stage],
      description: params[:description],
      contact_id: hubspot_contact_id
    )

    response = @activity_client.create_deal(deal_payload)

    if response && response['id'].present?
      Rails.logger.info "Deal created in HubSpot: #{response['id']}"
      { success: true, opportunity_id: response['id'].to_s }
    else
      { success: false, error: 'Failed to create deal', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating deal in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # TASK OPERATIONS
  # ============================================================================

  def create_task(params)
    contact = find_contact_from_params(params)
    hubspot_contact_id = contact&.additional_attributes&.dig('external', 'hubspot_lead_id')
    metadata = params[:metadata] || {}

    task_payload = Crm::Hubspot::Mappers::ActivityMapper.map_task(
      subject: metadata['task_subject'].presence || metadata['subject'].presence || params[:subject],
      description: metadata['description'].presence || params[:description],
      due_date: metadata['due_date'].presence || params[:due_date],
      contact_id: hubspot_contact_id
    )

    response = @activity_client.create_task(task_payload)

    if response && response['id'].present?
      Rails.logger.info "Task created in HubSpot: #{response['id']}"
      { success: true, task_id: response['id'].to_s }
    else
      { success: false, error: 'Failed to create task', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating task in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # EVENT (MEETING) OPERATIONS
  # ============================================================================

  def create_event(params)
    metadata = params[:metadata] || {}
    appointment_id = params[:appointment_id]
    appointment = appointment_id.present? ? Appointment.find_by(id: appointment_id) : nil

    contact = appointment&.contact || find_contact_from_params(params)
    hubspot_contact_id = contact&.additional_attributes&.dig('external', 'hubspot_lead_id')

    meeting_params = if appointment
                       {
                         subject: appointment.description.presence || 'Meeting from Nauto Console',
                         start_time: appointment.scheduled_at&.iso8601,
                         end_time: appointment.ended_at&.iso8601,
                         venue: appointment_venue(appointment),
                         contact_id: hubspot_contact_id
                       }
                     else
                       return { success: false, error: 'Event details required' } if metadata.blank? && params[:subject].blank?

                       {
                         subject: metadata['event_title'].presence || metadata['subject'].presence || params[:subject],
                         description: metadata['description'].presence || params[:description],
                         start_time: metadata['start_time'].presence || metadata['scheduled_at'].presence || params[:start_time],
                         end_time: metadata['end_time'].presence || params[:end_time],
                         venue: metadata['venue'].presence || params[:venue],
                         contact_id: hubspot_contact_id
                       }
                     end

    meeting_payload = Crm::Hubspot::Mappers::ActivityMapper.map_meeting(meeting_params)
    response = @activity_client.create_meeting(meeting_payload)

    if response && response['id'].present?
      event_id = response['id'].to_s
      appointment&.store_external_id('hubspot', event_id)
      Rails.logger.info "Meeting created in HubSpot: #{event_id}"
      { success: true, event_id: event_id }
    else
      { success: false, error: 'Failed to create meeting', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error creating meeting in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # NOTE OPERATIONS
  # ============================================================================

  def add_note(params)
    contact = find_contact_from_params(params)
    hubspot_contact_id = contact&.additional_attributes&.dig('external', 'hubspot_lead_id')

    return { success: false, error: 'Contact not synced to HubSpot' } unless hubspot_contact_id

    note_text = params[:note_text]
    return { success: false, error: 'Note text not provided' } unless note_text

    note_payload = Crm::Hubspot::Mappers::ActivityMapper.map_note(
      note_title: params[:note_title] || 'Note from Nauto Console',
      note_text: note_text,
      contact_id: hubspot_contact_id
    )

    response = @activity_client.create_note(note_payload)

    if response && response['id'].present?
      Rails.logger.info "Note added in HubSpot: #{response['id']}"
      { success: true, note_id: response['id'].to_s }
    else
      { success: false, error: 'Failed to create note', response: response }
    end
  rescue StandardError => e
    Rails.logger.error "Error adding note in HubSpot: #{e.message}"
    { success: false, error: e.message }
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  protected

  def build_client
    @contact_client
  end

  private

  def find_contact_from_params(params)
    contact_id = params[:contact_id]
    return Contact.find_by(id: contact_id) if contact_id

    if params[:email].present?
      Contact.find_by(email: params[:email], account_id: @hook.account_id)
    elsif params[:phone].present?
      Contact.find_by(phone_number: params[:phone], account_id: @hook.account_id)
    end
  end

  def store_external_id(contact, hubspot_id, key = 'hubspot_lead_id')
    contact.additional_attributes ||= {}
    contact.additional_attributes['external'] ||= {}
    contact.additional_attributes['external'][key] = hubspot_id
    contact.save(validate: false)
  end

  def get_external_id(contact, key = 'hubspot_lead_id')
    contact.additional_attributes&.dig('external', key)
  end

  def appointment_venue(appointment)
    case appointment.appointment_type
    when 'physical_visit'  then appointment.location || 'Office'
    when 'digital_meeting' then 'Video Call'
    when 'phone_call'      then 'Phone Call'
    end
  end
end
