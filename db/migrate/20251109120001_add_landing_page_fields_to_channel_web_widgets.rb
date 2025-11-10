class AddLandingPageFieldsToChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_web_widgets, :auto_generate_landing_page, :boolean, default: false, null: false
    add_column :channel_web_widgets, :landing_page_description, :text
    add_column :channel_web_widgets, :landing_page_url, :string
  end
end
