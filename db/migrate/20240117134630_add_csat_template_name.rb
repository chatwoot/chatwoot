class AddCsatTemplateName < ActiveRecord::Migration[7.0]
  def change
    add_column :csat_templates, :name, :string
  end
end
