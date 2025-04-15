class Crm::Leadsquared::Api::LeadClient < Crm::Leadsquared::Api::BaseClient
  # https://apidocs.leadsquared.com/quick-search/#api
  def search_lead(key)
    return { success: false, error: 'Search key is required' } if key.blank?

    path = 'LeadManagement.svc/Leads.GetByQuickSearch'
    params = { key: key }

    # Empty response: {:success=>true, :data=>[]}
    # Error response: {:success=>false, :error=>'Error message', :code=>404}

    get(path, params)
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
    # Success Response: {:success=>true, :data=>{"Status"=>"Success", "Message"=>{"Id"=>"8e0f69ae-e2ac-40fc-a0cf-827326181c8a"}}}
    # Error response: {:success=>false, :error=>'Error message', :code=>404}

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
    # success response: {:success=>true, :data=>{"Status"=>"Success", "Message"=>{"AffectedRows"=>1}}}
    # Error response: {:success=>false, :error=>'Error message', :code=>404}

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
    else
      Rails.logger.error("Call to LeadSquared leads API failed with [#{response[:code]}] #{response[:error]}")
      { success: false, error: 'No leads created or updated' }
    end
  end

  def valid_lead_create_or_update_response?(response)
    response[:success] &&
      response[:data].is_a?(Hash) &&
      response[:data]['Status'] == 'Success' &&
      response[:data]['Message'] &&
      response[:data]['Message']['Id'].present?
  end
end
