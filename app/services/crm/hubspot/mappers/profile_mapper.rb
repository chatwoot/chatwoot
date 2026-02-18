# frozen_string_literal: true

# Maps HubSpot Contact profile data to Nauto Console Contact attributes
class Crm::Hubspot::Mappers::ProfileMapper
  # Map HubSpot contact profile to Contact attributes
  #
  # @param crm_profile [Hash] HubSpot contact data from API
  # @return [Hash] Mapped contact attributes
  def self.map_to_contact_attributes(crm_profile)
    properties = crm_profile['properties'] || {}

    {}.tap do |attrs|
      # Basic fields
      attrs[:name] = build_full_name(properties)
      attrs[:phone_number] = properties['phone'] if properties['phone'].present?
      attrs[:email] = properties['email'] if properties['email'].present?

      # Additional attributes
      attrs[:additional_attributes] = build_additional_attributes(crm_profile, properties)
    end.compact
  end

  # Build full name from firstname and lastname
  def self.build_full_name(properties)
    [properties['firstname'], properties['lastname']].compact.join(' ').strip.presence
  end

  # Build additional_attributes hash
  def self.build_additional_attributes(profile, properties)
    {}.tap do |attrs|
      # Campos mapeados conocidos (para acceso rápido y queries)
      attrs['company_name'] = properties['company'] if properties['company'].present?
      attrs['city'] = properties['city'] if properties['city'].present?
      attrs['country'] = properties['country'] if properties['country'].present?

      # CRM metadata for tracking
      attrs['crm_metadata'] ||= {}
      attrs['crm_metadata']['hubspot'] = {
        'last_synced_at' => Time.current.iso8601,
        'lead_status' => properties['hs_lead_status'],
        'lifecycle_stage' => properties['lifecyclestage'],
        'crm_url' => profile_url(profile)
      }.compact

      # Raw profile data (TODOS los campos del CRM, incluyendo custom fields)
      # HubSpot retorna el perfil completo incluyendo properties
      attrs['crm_profiles'] ||= {}
      attrs['crm_profiles']['hubspot'] = profile
    end
  end

  # Build direct URL to contact in HubSpot
  def self.profile_url(profile)
    contact_id = profile['id']
    return nil if contact_id.blank?

    "https://app.hubspot.com/contacts/contact/#{contact_id}"
  end
end
