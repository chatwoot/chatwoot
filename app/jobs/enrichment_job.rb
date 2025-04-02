class EnrichmentJob < ApplicationJob
  queue_as :default

  def perform(params)
    enrich(params)
  end

  def enrich(params)
    id, email, name, company_name = params.values_at(:id, :email, :name, :company_name)

    contact = Contact.find_by(id: id)
    return unless contact

    enriched_data = enrich_from_people_data_labs(email, name, company_name)

    contact.name ||= "#{enriched_data[:first_name]} #{enriched_data[:last_name]}"
    contact.email ||= enriched_data[:email]
    contact.additional_attributes['company_name'] ||= enriched_data[:company_name]
    contact.additional_attributes['country'] ||= enriched_data[:country]
    contact.save

    all_profiles = enriched_data[:profiles]

    unique_networks = {}

    all_profiles.each do |entry|
      network = entry['network']
      url = entry['url']

      unique_networks[network] ||= url
    end

    if unique_networks
      contact.update(additional_attributes: contact.additional_attributes.merge({ 'social_profiles' => unique_networks }))

      Rails.logger.info("Updated contact #{contact.id} with social profiles: #{unique_networks}")
    else
      Rails.logger.info("Social profiles not found for #{params[:email]}")
    end

    Rails.logger.info("Unique networks: #{unique_networks}")
  end

  def enrich_from_people_data_labs(email, name, company_name)
    url = "#{ENV.fetch('PEOPLE_DATA_LABS_BASE_URL', nil)}#{ENV.fetch('PEOPLE_DATA_LABS_PEOPLE_ENRICH', nil)}"

    apiKey = ENV.fetch('PEOPLE_DATA_LABS_API_KEY', nil)

    headers = {
      content_type: :json,
      accept: :json,
      'X-API-Key': apiKey
    }

    params = {
      email: email,
      name: name,
      company: company_name,
      pretty: false,
      min_likelihood: 2,
      include_if_matched: false
    }.compact_blank

    query_string = URI.encode_www_form(params)
    full_url = "#{url}?#{query_string}"

    response = RestClient.get full_url, headers
    json_body = JSON.parse(response.body)
    {
      profiles: json_body.dig('data', 'profiles'),
      first_name: json_body.dig('data', 'first_name'),
      last_name: json_body.dig('data', 'last_name'),
      company_name: json_body.dig('data', 'job_company_name'),
      country: json_body.dig('data', 'countries')[0]
    }
  end
end
