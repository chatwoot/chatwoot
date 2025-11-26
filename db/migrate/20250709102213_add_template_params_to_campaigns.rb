class AddTemplateParamsToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :template_params, :jsonb
  end
end
