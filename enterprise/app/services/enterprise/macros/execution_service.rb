module Enterprise::Macros::ExecutionService
  def resolve_conversation(_params)
    return if required_attributes_missing?

    super
  end

  def change_status(status)
    return if status.first.to_s == 'resolved' && required_attributes_missing?

    super
  end

  private

  def required_attributes_missing?
    return false unless @account.feature_enabled?('conversation_required_attributes')

    defined_keys = @account.custom_attribute_definitions.conversation_attribute.pluck(:attribute_key)
    required_keys = @account.conversation_required_attributes.to_a & defined_keys
    return false if required_keys.blank?

    custom_attributes = @conversation.custom_attributes || {}
    required_keys.any? { |key| custom_attributes[key].to_s.blank? }
  end
end
