# frozen_string_literal: true

class RenameCampaignDeliveryReportErrorsColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :campaign_delivery_reports, :errors, :delivery_errors
  end
end
