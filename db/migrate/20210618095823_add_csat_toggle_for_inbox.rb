class AddCsatToggleForInbox < ActiveRecord::Migration[6.0]
  def change
    add_column :inboxes, :csat_survey_enabled, :boolean, default: false
  end
end
