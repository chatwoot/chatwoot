class BackfillEncryptedCaptainCustomToolCredentials < ActiveRecord::Migration[7.2]
  def up
    return unless Chatwoot.encryption_configured?

    custom_tool_model.find_each(&:encrypt)
  end

  def down
    return unless Chatwoot.encryption_configured?

    custom_tool_model.find_each(&:decrypt)
  end

  private

  def custom_tool_model
    Class.new(ActiveRecord::Base) do
      self.table_name = 'captain_custom_tools'
      encrypts :auth_config, :headers
    end
  end
end
