class ChangeEnableEmailCollectDefaultToFalse < ActiveRecord::Migration[7.1]
  def change
    change_column_default :inboxes, :enable_email_collect, from: true, to: false
  end
end

