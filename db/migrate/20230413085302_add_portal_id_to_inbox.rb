class AddPortalIdToInbox < ActiveRecord::Migration[6.1]
  def change
    add_reference :inboxes, :portal, foreign_key: true
  end
end
