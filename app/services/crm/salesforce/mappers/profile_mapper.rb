# frozen_string_literal: true

# Maps Salesforce Lead profile data to Nauto Console Contact attributes
class Crm::Salesforce::Mappers::ProfileMapper
  # Map Salesforce lead profile to Contact attributes
  #
  # @param crm_profile [Hash] Salesforce lead data from API
  # @return [Hash] Mapped contact attributes
  def self.map_to_contact_attributes(crm_profile)
    {}.tap do |attrs|
      # Basic fields
      attrs[:name] = build_full_name(crm_profile)
      attrs[:phone_number] = crm_profile['Phone'] if crm_profile['Phone'].present?
      attrs[:email] = crm_profile['Email'] if crm_profile['Email'].present?

      # Additional attributes
      attrs[:additional_attributes] = build_additional_attributes(crm_profile)
    end.compact
  end

  # Build full name from FirstName and LastName
  def self.build_full_name(profile)
    [profile['FirstName'], profile['LastName']].compact.join(' ').strip.presence
  end

  # Build additional_attributes hash
  def self.build_additional_attributes(profile)
    {}.tap do |attrs|
      # Campos mapeados conocidos (para acceso rápido y queries)
      attrs['company_name'] = profile['Company'] if profile['Company'].present?
      attrs['city'] = profile['City'] if profile['City'].present?
      attrs['country'] = profile['State'] if profile['State'].present?
      attrs['description'] = profile['Description'] if profile['Description'].present?

      # CRM metadata for tracking
      attrs['crm_metadata'] ||= {}
      attrs['crm_metadata']['salesforce'] = {
        'last_synced_at' => Time.current.iso8601,
        'status' => profile['Status'],
        'lead_source' => profile['LeadSource'],
        'rating' => profile['Rating'],
        'industry' => profile['Industry'],
        'crm_url' => profile_url(profile)
      }.compact

      # Raw profile data (TODOS los campos del CRM, incluyendo custom fields)
      attrs['crm_profiles'] ||= {}
      attrs['crm_profiles']['salesforce'] = profile.except('attributes')
    end
  end

  # Build direct URL to lead in Salesforce
  def self.profile_url(profile)
    return nil if profile['Id'].blank?

    # URL format: https://instance.salesforce.com/LeadId
    # Note: instance URL would need to come from hook credentials
    # For now, just store the ID to build URL later
    "salesforce://lead/#{profile['Id']}"
  end
end
