class CreateCannedResponseInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :canned_response_inboxes do |t|
      t.timestamps

      t.references :canned_response, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
    end
  end
end
