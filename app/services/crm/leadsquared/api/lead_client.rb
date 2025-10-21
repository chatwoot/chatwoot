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
  # We can pass the "SearchBy" attribute in the JSON body to search by a particular parameter, however
  # we don't need this capability at the moment
  def create_or_update_lead(lead_data)
    raise ArgumentError, 'Lead data is required' if lead_data.blank?

    path = 'LeadManagement.svc/Lead.CreateOrUpdate'

    formatted_data = format_lead_data(lead_data)
    response = post(path, {}, formatted_data)

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
end
