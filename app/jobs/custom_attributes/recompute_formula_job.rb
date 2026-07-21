class CustomAttributes::RecomputeFormulaJob < ApplicationJob
  queue_as :low

  # Triggered when source data (Conversation/Contact/Company) changes.
  # Recomputes the formula value on the target record and persists it.
  #
  # @param definition_id [Integer] CustomAttributeDefinition id
  # @param target_id [Integer] id of the record that owns the computed attribute
  def perform(definition_id, target_id)
    definition = CustomAttributeDefinition.find_by(id: definition_id)
    return if definition.blank?
    return unless definition.formula?

    service_class = recompute_service_for(definition)
    return if service_class.blank?

    target = target_record_for(definition, target_id)
    return if target.blank?

    service_class.new(target).perform
  rescue StandardError => e
    Rails.logger.warn(
      "[RecomputeFormulaJob] definition=#{definition_id} target=#{target_id} error=#{e.class}: #{e.message}"
    )
  end

  private

  def recompute_service_for(definition)
    {
      'contact_attribute' => CustomAttributes::RecomputeContactFormulasService,
      'conversation_attribute' => CustomAttributes::RecomputeConversationFormulasService,
      'company_attribute' => CustomAttributes::RecomputeCompanyFormulasService
    }[definition.attribute_model]
  end

  def target_record_for(definition, target_id)
    case definition.attribute_model
    when 'contact_attribute'
      Contact.find_by(id: target_id)
    when 'conversation_attribute'
      Conversation.find_by(id: target_id)
    when 'company_attribute'
      Company.find_by(id: target_id)
    end
  end
end
