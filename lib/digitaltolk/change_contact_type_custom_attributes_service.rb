class Digitaltolk::ChangeContactTypeCustomAttributesService
  attr_accessor :conversation, :contact_type

  def initialize(conversation, contact_type)
    @conversation = conversation
    @contact_type = contact_type
  end

  def perform
    return false if @contact_type.blank?
    return true if contact_type_attribute == @contact_type

    set_custom_atributes
    true
  end

  private

  def contact_type_attribute
    @conversation.custom_attributes[CustomAttributeDefinition::CONTACT_TYPE]
  end

  def set_custom_atributes
    attrs = @conversation.custom_attributes || {}
    attrs[CustomAttributeDefinition::CONTACT_TYPE] = @contact_type

    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_column(:custom_attributes, attrs)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
