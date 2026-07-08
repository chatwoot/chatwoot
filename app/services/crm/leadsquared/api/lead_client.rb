class Crm::Leadsquared::Api::LeadClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/quick-search/#api
  def search_lead(key)
    raise ArgumentError, 'Search key is required' if key.blank?

    path = 'LeadManagement.svc/Leads.GetByQuickSearch'
    params = { key: key }

    get(path, params)
  end

  # https://apidocs.leadsquared.com/create-or-update/#api
  # The email address and phone fields are used as the default search criteria.
  # If none of these match with an existing lead, a new lead will be created.
  # We pass the "SearchBy" attribute with value "Phone" when a MXDuplicateEntryException
  # occurs, indicating a duplicate mobile number match that the default search missed.
  def create_or_update_lead(lead_data)
    raise ArgumentError, 'Lead data is required' if lead_data.blank?

    path = 'LeadManagement.svc/Lead.CreateOrUpdate'
    formatted_data = format_lead_data(lead_data)

    response = post(path, {}, formatted_data)
    response['Message']['Id']
  rescue ApiError => e
    raise unless duplicate_phone_error?(e) && lead_data.key?('Mobile')

    Rails.logger.warn 'LeadSquared duplicate phone detected, retrying with SearchBy=Phone'
    response = post(path, {}, formatted_data + [{ 'Attribute' => 'SearchBy', 'Value' => 'Phone' }])
    response['Message']['Id']
  end

  def update_lead(lead_data, lead_id)
    raise ArgumentError, 'Lead ID is required' if lead_id.blank?
    raise ArgumentError, 'Lead data is required' if lead_data.blank?

    path = "LeadManagement.svc/Lead.Update?leadId=#{lead_id}"
    formatted_data = format_lead_data(lead_data)

    response = post(path, {}, formatted_data)

    response['Message']['AffectedRows']
  end

  private

  def format_lead_data(lead_data)
    lead_data.map do |key, value|
      {
        'Attribute' => key,
        'Value' => value
      }
    end
  end

  def duplicate_phone_error?(error)
    return false if error.response.blank?

    parsed = error.response.parsed_response
    parsed.is_a?(Hash) && parsed['ExceptionType'] == 'MXDuplicateEntryException'
  rescue StandardError
    false
  end
end
