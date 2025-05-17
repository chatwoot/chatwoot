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
      'Mobile' => contact.phone_number.presence,
      'Source' => brand_name
    }.compact
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'] || 'Chatwoot'
  end

  def brand_name_without_spaces
    brand_name.gsub(/\s+/, '')
  end
end
