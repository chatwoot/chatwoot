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

    return if enriched_data.nil?

    contact.update(name: "#{enriched_data[:first_name]} #{enriched_data[:last_name]}") if contact.name.blank?

    contact.update(phone_number: enriched_data[:phone_number]) if contact.phone_number.blank?

    if contact.additional_attributes['city'].blank?
      contact.update(additional_attributes: contact.additional_attributes.merge({ city: enriched_data[:city] }))
    end

    if contact.additional_attributes['country'].blank?
      c = enriched_data[:country]
      c_code = country_code_from_country_name(c)
      c_display_name = display_country_name_from_code(c_code)

      contact.update(additional_attributes: contact.additional_attributes.merge({ country: c_display_name }))
    end

    if contact.additional_attributes['company_name'].blank?
      contact.update(additional_attributes: contact.additional_attributes.merge({ company_name: enriched_data[:company_name] }))
    end

    contact.save

    all_profiles = enriched_data[:profiles]

    if all_profiles
      contact.update(additional_attributes: contact.additional_attributes.merge({ 'social_profiles' => all_profiles }))

      Rails.logger.info("Updated contact #{contact.id} with social profiles: #{all_profiles}")
    else
      Rails.logger.info("Social profiles not found for #{params[:email]}")
    end

    Rails.logger.info("Unique networks: #{all_profiles}")
  end

  def country_code_from_country_name(country_str)
    file = File.read('./shared/people_data_labs_countries.json')
    countries_json = JSON.parse(file)
    c_code = countries_json[country_str]
    c_code
  end

  def display_country_name_from_code(country_code)
    file = File.read('./shared/countries.json')
    countries_json = JSON.parse(file)
    required_country = countries_json.find { |country| country['id'] == country_code }
    required_country['name']
  end

  def enrich_from_people_data_labs(email, name, company_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    response = get_data_from_pdf(email, name, company_name)
    json_body = JSON.parse(response.body)

    return nil if !json_body.key?('data') || !json_body['data'].is_a?(Hash)

    json_data = json_body['data']

    is_work_profile = work_profile?(email, json_data)
    {
      profiles: get_profiles(is_work_profile, json_data),
      first_name: json_data['first_name'],
      last_name: json_data['last_name'],
      company_name: json_data['job_company_name'],
      country: json_data['countries'][0],
      city: get_city(json_data),
      phone_number: get_mobile_phone(json_data)
    }
  end

  def get_mobile_phone(json_data)
    phone_numbers = json_data['phone_numbers']
    return '' unless phone_numbers.is_a?(Array)

    phone_numbers.first || ''
  end

  def get_city(json_data)
    locations = json_data['location_names']
    return '' unless locations.is_a?(Array)

    locations.first || ''
  end

  def get_profiles(is_work_profile, json_data) # rubocop:disable Metrics/MethodLength
    user_profiles = {
      'linkedin': json_data['linkedin_url'],
      'twitter': json_data['twitter_url'],
      'facebook': json_data['facebook_url'],
      'github': json_data['github_url']
    }
    return user_profiles unless is_work_profile

    company_profiles = {
      'linkedin': json_data['job_company_linkedin_url'],
      'twitter': json_data['job_company_twitter_url'],
      'facebook': json_data['job_company_facebook_url']
    }
    user_profiles.merge!(company_profiles) { |_key, user_val, company_val| user_val.presence || company_val }
    user_profiles
  end

  def work_profile?(email, json_data)
    work_email = json_data['work_email']

    if work_email.is_a?(TrueClass) || work_email.is_a?(FalseClass)
      work_email
    elsif work_email.is_a?(String)
      work_email == email
    end
  end

  def get_data_from_pdf(email, name, company_name) # rubocop:disable Metrics/MethodLength
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

    begin
      RestClient.get full_url, headers
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.warn "PDL Error #{e.http_code}: #{e.message} => #{e.response.body}"
      e.response
    rescue RestClient::Exception => e
      Rails.logger.error "REST Client Exception: #{e.class} - #{e.message}"
      {
        error: {
          type: "Rest client error",
          message: "Internal error"
        }
      }
    end
  end
end
