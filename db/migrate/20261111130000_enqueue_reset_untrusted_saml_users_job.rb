class EnqueueResetUntrustedSamlUsersJob < ActiveRecord::Migration[7.1]
  def up
    Migration::ResetUntrustedSamlUsersJob.perform_later if ChatwootApp.enterprise?
  end

  def down; end
end
