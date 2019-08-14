class Latlong < ActiveRecord::Migration[5.0]
  def change
    change_column :attachments, :coordinates_lat, :float, default: 0
    change_column :attachments, :coordinates_long, :float, default: 0
  end
end
