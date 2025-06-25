class AddTriggerOnlyDuringBusinessHoursCollectToCampaigns < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :trigger_only_during_business_hours, :boolean, default: false
  end
end
