module CustomAttributeHandler
  extend ActiveSupport::Concern

  def create_default_calling_attributes
    # Create Calling Status attribute (list type)
    CustomAttributeDefinition.find_or_create_by!(
      account: self,
      attribute_key: 'calling_status',
      attribute_model: :conversation_attribute
    ) do |cad|
      cad.attribute_display_name = 'Calling Status'
      cad.attribute_display_type = :list
      cad.attribute_values = ['Scheduled', 'Not Picked', 'Follow-up', 'Converted', 'Dropped']
      cad.attribute_description = 'Track the status of calls for conversations'
    end

    # Create Calling Notes attribute (text type)
    CustomAttributeDefinition.find_or_create_by!(
      account: self,
      attribute_key: 'calling_notes',
      attribute_model: :conversation_attribute
    ) do |cad|
      cad.attribute_display_name = 'Calling Notes'
      cad.attribute_display_type = :text
      cad.attribute_description = 'Notes related to calls for this conversation'
    end
  end
end
