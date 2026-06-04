class AddCustomHtmlToPortals < ActiveRecord::Migration[7.1]
  def change
    add_column :portals, :custom_head_html, :text
    add_column :portals, :custom_body_html, :text
  end
end
