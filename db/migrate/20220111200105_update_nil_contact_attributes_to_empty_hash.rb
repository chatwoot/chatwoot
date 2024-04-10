class UpdateNilContactAttributesToEmptyHash < ActiveRecord::Migration[6.1]
  def change
    # rubocop:disable Rails/SkipsModelValidations
    Contact.where(custom_attributes: nil).update_all(custom_attributes: {})
    Contact.where(additional_attributes: nil).update_all(additional_attributes: {})
    # rubocop:enable Rails/SkipsModelValidations
  end
end
