class ChangeMessageToBeNullableInCampaigns < ActiveRecord::Migration[7.0]
  def change
    change_column_null :campaigns, :message, true
  end
end
