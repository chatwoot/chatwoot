class DropNumberFormatConfigs < ActiveRecord::Migration[7.0]
  def change
    drop_table :number_format_configs
  end
end
