class AddDraftStatusToCampaigns < ActiveRecord::Migration[7.1]
  # Rails integer enum values (application-level; no column change):
  # active = 0, completed = 1, processing = 2, draft = 3
  def change
    # no-op: campaign_status remains an integer column
  end
end
