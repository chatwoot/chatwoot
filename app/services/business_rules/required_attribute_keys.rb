# frozen_string_literal: true

class BusinessRules::RequiredAttributeKeys
  def self.resolve(account:, attribute_keys: [], attribute_category_keys: [], attribute_model: :conversation_attribute)
    keys = Array(attribute_keys).map(&:to_s).reject(&:blank?)
    categories = Array(attribute_category_keys).map(&:to_s).reject(&:blank?)
    return keys.uniq if categories.blank?

    category_keys = account.custom_attribute_definitions
                           .where(attribute_model: attribute_model, category: categories)
                           .reject(&:formula?)
                           .map { |definition| definition.attribute_key.to_s }

    (keys + category_keys).uniq
  end
end
