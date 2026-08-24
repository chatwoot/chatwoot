module Enterprise::Concerns::CustomAttributeDefinition
  extend ActiveSupport::Concern

  included do
    after_destroy :cleanup_conversation_required_attributes
  end

  private

  def cleanup_conversation_required_attributes
    # account can be nil here when this runs from the account's destroy_async
    # cleanup job, which only destroys definitions after the account row is gone.
    return unless account && conversation_attribute? && account.conversation_required_attributes&.include?(attribute_key)

    account.conversation_required_attributes = account.conversation_required_attributes - [attribute_key]
    account.save!
  end
end
