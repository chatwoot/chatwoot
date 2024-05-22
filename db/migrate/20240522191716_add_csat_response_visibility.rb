class AddCsatResponseVisibility < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_response_visible, :boolean, default: false, null: false
  end
end
