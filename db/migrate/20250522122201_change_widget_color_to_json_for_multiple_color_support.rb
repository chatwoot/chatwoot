class ChangeWidgetColorToJsonForMultipleColorSupport < ActiveRecord::Migration[7.0]
  def up
    add_column :channel_web_widgets, :logo_colors, :jsonb, default: {dot1: "#33a854", dot2: "#fabc05", dot3: "#ea4234" }, null: false

    # Backfill color_json with existing color1 values
    Channel::WebWidget.reset_column_information
    Channel::WebWidget.find_each do |record|
      record.update_column(:logo_colors, {dot1: "#33a854", dot2: "#fabc05", dot3: "#ea4234" })
    end
  end

  def down
    remove_column :channel_web_widgets, :logo_colors
  end
end
