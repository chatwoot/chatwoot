class SetContentTypeTextForTheOldMessages < ActiveRecord::Migration[6.1]
  def change
    Message.where(content_type: nil).update_all(content_type: 0)
  end
end
