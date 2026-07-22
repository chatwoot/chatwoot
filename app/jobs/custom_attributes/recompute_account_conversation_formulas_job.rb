class CustomAttributes::RecomputeAccountConversationFormulasJob < ApplicationJob
  queue_as :low

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return if account.blank?
    return unless account.custom_attribute_definitions.conversation_attribute.where.not(formula: nil).exists?

    account.conversations.find_each(batch_size: 100) do |conversation|
      CustomAttributes::RecomputeConversationFormulasService.new(conversation: conversation).perform
    rescue StandardError => e
      Rails.logger.warn(
        "[RecomputeAccountConversationFormulasJob] conversation=#{conversation.id} error=#{e.class}: #{e.message}"
      )
    end
  end
end
