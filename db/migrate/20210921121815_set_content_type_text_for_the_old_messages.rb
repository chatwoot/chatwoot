class SetContentTypeTextForTheOldMessages < ActiveRecord::Migration[6.1]
  def change
    # rubocop:disable Rails/SkipsModelValidations
    Message.where(content_type: nil).update_all(content_type: 0)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
