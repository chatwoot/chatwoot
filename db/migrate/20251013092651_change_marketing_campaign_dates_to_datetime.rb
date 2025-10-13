class ChangeMarketingCampaignDatesToDatetime < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        change_column :marketing_campaigns, :start_date, :datetime
        change_column :marketing_campaigns, :end_date, :datetime
      end

      dir.down do
        change_column :marketing_campaigns, :start_date, :date
        change_column :marketing_campaigns, :end_date, :date
      end
    end
  end
end
