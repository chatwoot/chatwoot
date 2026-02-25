class Crm::Leadsquared::Mappers::ContactMapper
  def self.map(contact)
    new(contact).map
  end

  def initialize(contact)
    @contact = contact
  end

  def map
    base_attributes
  end

  private

  attr_reader :contact

  def base_attributes
    {
      'FirstName' => contact.name.presence,
      'LastName' => contact.last_name.presence,
      'EmailAddress' => contact.email.presence,
      'Mobile' => formatted_phone_number,
      'Source' => brand_name
    }.compact
  end

  def formatted_phone_number
    # it seems like leadsquared needs a different phone number format
    # it's not documented anywhere, so don't bother trying to look up online
    # After some trial and error, I figured out the format, its +<country_code>-<national_number>
    return nil if contact.phone_number.blank?

    parsed = TelephoneNumber.parse(contact.phone_number)
    return contact.phone_number unless parsed.valid?

    country_code = parsed.country.country_code
    e164 = parsed.e164_number
    e164 = e164.sub(/^\+/, '')

    national_number = e164.sub(/^#{Regexp.escape(country_code)}/, '')

    "+#{country_code}-#{national_number}"
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'] || 'Chatwoot'
  end

  def brand_name_without_spaces
    brand_name.gsub(/\s+/, '')
  end
end
