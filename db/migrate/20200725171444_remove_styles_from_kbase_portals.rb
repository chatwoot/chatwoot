class RemoveStylesFromKbasePortals < ActiveRecord::Migration[6.0]
  def change
    change_table :kbase_portals, bulk: true do |_t|
      remove_column :kbase_portals, :phone, :string
      remove_column :kbase_portals, :bg_body_color, :string
      remove_column :kbase_portals, :bg_header_color, :string
      remove_column :kbase_portals, :bg_footer_color, :string
      remove_column :kbase_portals, :bg_helpcenter_color, :string
      remove_column :kbase_portals, :tab_bg_color, :string
      remove_column :kbase_portals, :tab_active_color, :string
      remove_column :kbase_portals, :portal_base_font, :string
      remove_column :kbase_portals, :portal_base_color, :string
      remove_column :kbase_portals, :portal_heading_font, :string
      remove_column :kbase_portals, :portal_heading_color, :string
      remove_column :kbase_portals, :link_text_color, :string
      remove_column :kbase_portals, :link_text_hover_color, :string
      remove_column :kbase_portals, :form_input_focus_glow_color, :string
      remove_column :kbase_portals, :form_primary_btn_color, :string
      remove_column :kbase_portals, :show_author, :boolean
      remove_column :kbase_portals, :linkback_url, :string
    end
  end
end
