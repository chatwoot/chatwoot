# frozen_string_literal: true

class AddDateAttributeToSavedReportPanels < ActiveRecord::Migration[7.1]
  def change
    add_column :saved_report_panels, :date_attribute, :string, null: false, default: ''
  end
end
