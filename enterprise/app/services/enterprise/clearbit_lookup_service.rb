# The Enterprise::ClearbitLookupService class is responsible for interacting with the Clearbit API.
# It provides methods to lookup a person's information using their email.
# Clearbit API documentation: {https://dashboard.clearbit.com/docs?ruby#api-reference}
# Persons API: {https://dashboard.clearbit.com/docs?ruby=#enrichment-api-person-api}
#
# Note: The Clearbit gem is not used in this service, since it is not longer maintained
# GitHub: {https://github.com/clearbit/clearbit-ruby}
#
# @example
#   Enterprise::ClearbitLookupService.lookup('test@example.com')
class Enterprise::ClearbitLookupService
  # Clearbit API endpoint for combined lookup
  CLEARBIT_ENDPOINT = 'https://person.clearbit.com/v2/combined/find'.freeze

  # Performs a lookup on the Clearbit API using the provided email.
  #
  # @param email [String] The email address to lookup.
  # @return [Hash, nil] A hash containing the person's full name, company name, and company timezone, or nil if an error occurs.
  def self.lookup(email)
    return nil unless clearbit_enabled?

    options = {
      headers: { 'Authorization' => "Bearer #{ENV.fetch('CLEARBIT_API_KEY', nil)}" },
      query: { email: email }
    }

    response = HTTParty.get(CLEARBIT_ENDPOINT, options)

    if response.success?
      data = response.parsed_response
      format_response(data)
    else
      Rails.logger.error "[ClearbitLookup] API Error: #{response.message} (Status: #{response.code})"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[ClearbitLookup] #{e.message}"
    nil
  end

  # Checks if Clearbit is enabled by checking for the presence of the CLEARBIT_API_KEY environment variable.
  #
  # @return [Boolean] True if Clearbit is enabled, false otherwise.
  def self.clearbit_enabled?
    ENV['CLEARBIT_API_KEY'].present?
  end

  # Formats the response data from the Clearbit API.
  #
  # @param data [Hash] The raw data from the Clearbit API.
  # @return [Hash] A hash containing the person's full name, company name, and company timezone.
  def self.format_response(data)
    {
      name: data.dig('person', 'name', 'fullName'),
      company_name: data.dig('company', 'name'),
      timezone: data.dig('company', 'timeZone')
    }
  end
end
