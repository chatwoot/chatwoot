class Conversations::ClearSkipCsatFlagJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    return unless conversation.additional_attributes&.[]('skip_csat')

    updated_attributes = conversation.additional_attributes.dup
    updated_attributes.delete('skip_csat')
    conversation.update_column(:additional_attributes, updated_attributes) # rubocop:disable Rails/SkipsModelValidations
    Rails.logger.info("Cleared skip_csat flag for conversation #{conversation.id} via job")
  end
end
