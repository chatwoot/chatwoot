module ConversationCustomAttributesConcern
  def custom_attributes
    attributes = params.permit(custom_attributes: {})[:custom_attributes]
    # When `merge` is truthy, only the keys sent are updated and the rest are kept, matching the contacts endpoint.
    # Replace stays the default so existing integrations are unaffected.
    attributes = @conversation.custom_attributes.merge(attributes || {}) if ActiveModel::Type::Boolean.new.cast(params[:merge])
    @conversation.custom_attributes = attributes
    @conversation.save!
  end

  def destroy_custom_attributes
    @conversation.custom_attributes = @conversation.custom_attributes.excluding(params[:custom_attributes])
    @conversation.save!
  end
end
