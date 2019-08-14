class CreateCannedResponses < ActiveRecord::Migration[5.0]
  def change
    create_table :canned_responses do |t|
      t.integer :account_id
      t.string :short_code
      t.text :content

      t.timestamps
    end
  end
end
