class CreateCannedResponseScopes < ActiveRecord::Migration[7.1]
  def change
    create_table :canned_response_scopes do |t|
      t.references :canned_response, null: false, foreign_key: true
      t.integer :user_ids, array: true, default: []
      t.integer :team_ids, array: true, default: []
      t.integer :inbox_ids, array: true, default: []

      t.timestamps
    end
  end
end
