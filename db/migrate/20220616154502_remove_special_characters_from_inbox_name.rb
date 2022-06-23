class RemoveSpecialCharactersFromInboxName < ActiveRecord::Migration[6.1]
  # This PR tried to remove special characters from the inbox name
  # It broke in the Chatwoot Cloud as there were inboxes with valid special characters
  # We had to push a temporary fix to continue the deployment by removing the logic
  # from this migration. Keeping this migration here to remove inconsistency.

  def change; end
end
