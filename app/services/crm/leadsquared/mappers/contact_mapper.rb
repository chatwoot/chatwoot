class Crm::Leadsquared::Mappers::ContactMapper
  def self.map(contact)
    new(contact).map
  end

  def initialize(contact)
    @contact = contact
  end

  def map
    base_attributes.merge(additional_attributes).merge(brand_attributes)
  end

  private

  attr_reader :contact

  def base_attributes
    {
      'FirstName' => contact.name.presence,
      'LastName' => contact.last_name.presence,
      'EmailAddress' => contact.email.presence,
      'Mobile' => contact.phone_number.presence
    }.compact
  end

  def additional_attributes
    return {} if contact.additional_attributes.blank?

    {
      'mx_Company' => contact.additional_attributes['company_name'].presence,
      'mx_Address' => contact.additional_attributes['address'].presence,
      'mx_City' => contact.additional_attributes['city'].presence,
      'mx_Country' => contact.additional_attributes['country'].presence
    }.compact
  end

  def brand_attributes
    {
      'Source' => brand_name
    }
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'] || 'Chatwoot'
  end

  def brand_name_without_spaces
    brand_name.gsub(/\s+/, '')
  end
end
