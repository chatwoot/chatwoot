class Crm::Leadsquared::Api::LeadClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/quick-search/#api
  def search_lead(key)
    return { success: false, error: 'Search key is required' } if key.blank?

    path = '/LeadManagement.svc/Leads.GetByQuickSearch'
    params = { key: key }

    response = get(path, params)

    # For Quick Search API, empty array means no matching leads found
    return { success: true, data: nil } if response[:success] && response[:data].is_a?(Array) && response[:data].empty?

    response
  end

  # https://apidocs.leadsquared.com/create-or-update/#api
  # The email address and phone fields are used as the default search criteria.
  # If none of these match with an existing lead, a new lead will be created.
  # We can pass the “SearchBy” attribute in the JSON body to search by a particular parameter, however
  # we don't need this capability at the moment
  def create_or_update_lead(lead_data)
    return { success: false, error: 'Lead data is required' } if lead_data.blank?

    path = 'LeadManagement.svc/Lead.CreateOrUpdate'

    # LeadSquared expects an array of attribute objects
    # Each having 'Attribute' and 'Value' keys
    formatted_data = lead_data.map do |key, value|
      {
        'Attribute' => key,
        'Value' => value
      }
    end

    response = post(path, {}, formatted_data)

    handle_lead_create_or_update_response(response)
  end

  def update_lead(lead_data, lead_id)
    return { success: false, error: 'Lead ID is required' } if lead_id.blank?

    path = "LeadManagement.svc/Lead.Update?leadId=#{lead_id}"

    # LeadSquared expects an array of attribute objects
    # Each having 'Attribute' and 'Value' keys
    formatted_data = lead_data.map do |key, value|
      {
        'Attribute' => key,
        'Value' => value
      }
    end

    response = post(path, {}, formatted_data)
    if response[:success]
      response
    else
      Rails.logger.error("Lead update failed: #{response}")
      { success: false, error: 'Lead update failed' }
    end
  end

  private

  def handle_lead_create_or_update_response(response)
    if valid_lead_create_or_update_response?(response)
      { success: true, data: response[:data]['Message'] }
    elsif response[:success]
      # Response was technically successful but no lead ID returned
      { success: false, error: 'No leads created or updated' }
    else
      response
    end
  end

  def valid_lead_create_or_update_response?(response)
    response[:success] &&
      valid_response_data?(response[:data])
  end

  def valid_response_data?(data)
    data.is_a?(Hash) &&
      data['Status'] == 'Success' &&
      data['Message'] &&
      data['Message']['Id'].present?
  end
end
