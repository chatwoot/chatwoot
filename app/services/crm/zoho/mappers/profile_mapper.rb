# frozen_string_literal: true

# Maps Zoho Lead profile data to Nauto Console Contact attributes
class Crm::Zoho::Mappers::ProfileMapper
  # Map Zoho lead profile to Contact attributes
  #
  # @param crm_profile [Hash] Zoho lead data from API
  # @param org_id [String] Zoho organization ID (optional, for URL construction)
  # @return [Hash] Mapped contact attributes
  def self.map_to_contact_attributes(crm_profile, org_id: nil)
    {}.tap do |attrs|
      # Basic fields
      attrs[:name] = build_full_name(crm_profile)
      attrs[:phone_number] = crm_profile['Phone'] if crm_profile['Phone'].present?
      attrs[:email] = crm_profile['Email'] if crm_profile['Email'].present?

      # Additional attributes
      attrs[:additional_attributes] = build_additional_attributes(crm_profile, org_id)
    end.compact
  end

  # Build full name from First_Name and Last_Name
  def self.build_full_name(profile)
    [profile['First_Name'], profile['Last_Name']].compact.join(' ').strip.presence
  end

  # Build additional_attributes hash
  def self.build_additional_attributes(profile, org_id)
    {}.tap do |attrs|
      # Campos mapeados conocidos (para acceso rápido y queries)
      attrs['company_name'] = profile['Company'] if profile['Company'].present?
      attrs['city'] = profile['City'] if profile['City'].present?
      attrs['country'] = profile['State'] if profile['State'].present?
      attrs['description'] = profile['Description'] if profile['Description'].present?

      # CRM metadata for tracking
      attrs['crm_metadata'] ||= {}
      attrs['crm_metadata']['zoho'] = {
        'last_synced_at' => Time.current.iso8601,
        'lead_status' => profile['Lead_Status'],
        'lead_source' => profile['Lead_Source'],
        'rating' => profile['Rating'],
        'industry' => profile['Industry'],
        'crm_url' => profile_url(profile, org_id)
      }.compact

      # Raw profile data (TODOS los campos del CRM, incluyendo custom fields)
      attrs['crm_profiles'] ||= {}
      attrs['crm_profiles']['zoho'] = profile.except('$approval', '$review', '$currency_symbol', '$review_process')
    end
  end

  # Build direct URL to lead in Zoho
  # Format: https://crm.zoho.com/crm/org{org_id}/tab/Leads/{lead_id}
  def self.profile_url(profile, org_id)
    lead_id = profile['id']
    return nil unless lead_id.present? && org_id.present?

    "https://crm.zoho.com/crm/org#{org_id}/tab/Leads/#{lead_id}"
  end
end
