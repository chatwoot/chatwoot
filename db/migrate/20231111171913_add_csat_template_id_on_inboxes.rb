class AddCsatTemplateIdOnInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_template_id, :integer
  end
end
