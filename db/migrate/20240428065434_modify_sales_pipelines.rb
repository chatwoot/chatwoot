class ModifySalesPipelines < ActiveRecord::Migration[7.0]
  def change
    rename_column :sales_pipelines, :short_name, :code
    add_column :sales_pipelines, :allow_disabled, :boolean, default: false, null: false
    rename_table :sales_pipelines, :stages
  end
end
