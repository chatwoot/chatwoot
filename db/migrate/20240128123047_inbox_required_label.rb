class InboxRequiredLabel < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :label_required, :boolean, default: false
  end
end
