class ContactDrop < BaseDrop
  def name
    @obj.try(:name).try(:split).try(:map, &:capitalize).try(:join, ' ')
  end

  def email
    @obj.try(:email)
  end

  def phone_number
    @obj.try(:phone_number)
  end

  def phone
    @obj.try(:phone_number)
  end

  def first_name
    @obj.try(:name).try(:split).try(:first).try(:capitalize)
  end

  def last_name
    @obj.try(:name).try(:split).try(:last).try(:capitalize) if @obj.try(:name).try(:split).try(:size) > 1
  end

  def document_number
    @obj.try(:document_number)
  end

  def identifier
    @obj.try(:identifier)
  end

  def country_code
    @obj.try(:country_code)
  end

  def city
    @obj.try(:additional_attributes).try(:[], 'city')
  end

  def company_name
    @obj.try(:additional_attributes).try(:[], 'company_name')
  end

  def assigned_agent
    agent = @obj.try(:assigned_agent)
    agent.present? ? UserDrop.new(agent) : nil
  end

  def custom_attribute
    custom_attributes = @obj.try(:custom_attributes) || {}
    custom_attributes.transform_keys(&:to_s)
  end
end
