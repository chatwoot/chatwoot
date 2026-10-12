class BackfillEncryptedCaptainCustomToolCredentials < ActiveRecord::Migration[7.2]
  def up
    return unless ChatwootApp.enterprise? && Chatwoot.encryption_configured?

    Captain::CustomTool.find_each(&:encrypt)
  end

  def down
    return unless ChatwootApp.enterprise? && Chatwoot.encryption_configured?

    Captain::CustomTool.find_each(&:decrypt)
  end
end
