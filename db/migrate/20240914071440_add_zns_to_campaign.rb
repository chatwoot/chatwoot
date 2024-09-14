class AddZnsToCampaign < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :is_zns, :boolean, default: false, null: false
    add_column :campaigns, :zns_template_id, :text, null: true
    add_column :campaigns, :zns_template_data, :jsonb, null: true
    add_column :campaigns, :sent_count, :integer, default: 0, null: false
    add_column :campaigns, :received_count, :integer, default: 0, null: false
  end
end
