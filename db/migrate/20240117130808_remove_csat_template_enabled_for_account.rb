class RemoveCsatTemplateEnabledForAccount < ActiveRecord::Migration[7.0]
  def change
    remove_column :accounts, :csat_template_enabled
  end
end
