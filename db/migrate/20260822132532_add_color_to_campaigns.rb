class AddColorToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :color, :string, default: '#1f93ff', null: false
  end
end
