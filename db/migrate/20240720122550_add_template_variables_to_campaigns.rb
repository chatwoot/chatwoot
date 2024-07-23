class AddTemplateVariablesToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :template_variables, :json
  end
end
