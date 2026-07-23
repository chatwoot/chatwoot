# frozen_string_literal: true

class AddCustomDateRangeToSavedReportPanels < ActiveRecord::Migration[7.1]
  def change
    return unless table_exists?(:saved_report_panels)

    add_column :saved_report_panels, :custom_since, :bigint unless column_exists?(:saved_report_panels, :custom_since)
    add_column :saved_report_panels, :custom_until, :bigint unless column_exists?(:saved_report_panels, :custom_until)
  end
end
