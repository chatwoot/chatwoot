class CreateKbasePortals < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_portals do |t|
      t.integer :account_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :custom_domain
      t.string :color
      t.string :homepage_link
      t.string :page_title
      t.text   :header_text

      t.index :slug, unique: true
      t.timestamps
    end
  end
end
