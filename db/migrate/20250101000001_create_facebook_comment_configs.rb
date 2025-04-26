class CreateFacebookCommentConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :facebook_comment_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :webhook_url, null: false
      t.integer :status, default: 0
      t.jsonb :additional_attributes, default: {}
      t.timestamps
    end
    
    add_index :facebook_comment_configs, [:account_id, :inbox_id], unique: true
  end
end
