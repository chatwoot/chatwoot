class AddStyleToKbasePortals < ActiveRecord::Migration[6.0]
  def change
    change_table :kbase_portals, bulk: true do |_t|
      add_column :kbase_portals, :homepage_link, :string
      add_column :kbase_portals, :page_title, :string
      add_column :kbase_portals, :header_text, :text
      add_column :kbase_portals, :header_image, :string
      add_column :kbase_portals, :social_media_image, :string
      add_column :kbase_portals, :color, :string
      add_column :kbase_portals, :footer_title, :string
      add_column :kbase_portals, :footer_url, :string
    end
  end
end
