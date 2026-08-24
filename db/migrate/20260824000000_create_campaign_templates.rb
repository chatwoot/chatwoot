class CreateCampaignTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_templates do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :campaign_templates, [:account_id, :name], unique: true
  end
end
