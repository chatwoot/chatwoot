class CreateKbasePortals < ActiveRecord::Migration[6.0]
  def change
    create_table :kbase_portals do |t|
      t.integer :account_id
      t.string :name
      t.string :subdomain
      t.string :custom_domain
      t.boolean :show_author
      t.string :logo
      t.string :favicon
      t.string :linkback_url
      t.string :phone
      t.string :bg_body_color
      t.string :bg_header_color
      t.string :bg_footer_color
      t.string :bg_helpcenter_color
      t.string :tab_bg_color
      t.string :tab_active_color
      t.string :portal_base_font
      t.string :portal_base_color
      t.string :portal_heading_font
      t.string :portal_heading_color
      t.string :link_text_color
      t.string :link_text_hover_color
      t.string :form_input_focus_glow_color
      t.string :form_primary_btn_color

      t.timestamps
    end
  end
end
