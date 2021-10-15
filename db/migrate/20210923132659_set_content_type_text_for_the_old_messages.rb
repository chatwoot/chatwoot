class SetContentTypeTextForTheOldMessages < ActiveRecord::Migration[6.1]
  def change
    change_column_null(:messages, :content_type, false, 0)
  end
end
