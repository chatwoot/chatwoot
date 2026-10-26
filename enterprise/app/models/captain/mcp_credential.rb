# OAuth state and tokens of MCP servers, stored the way RubyLLM's own credential store does.
# RubyLLM always encrypts the data, which fails on installs without encryption keys, so Chatwoot
# encrypts it only when keys are configured, like other secrets.
class Captain::McpCredential < ApplicationRecord
  self.table_name = 'ruby_llm_mcp_credentials'

  belongs_to :owner, polymorphic: true, optional: true

  serialize :data, coder: JSON
  encrypts :data if Chatwoot.encryption_configured?

  validates :key, presence: true

  def self.read(key)
    find_by(key: key)&.data
  end

  def self.write(key, data, owner: nil)
    find_or_initialize_by(key: key).update!(data: data, owner: owner.is_a?(ActiveRecord::Base) ? owner : nil)
  end

  def self.delete(key)
    where(key: key).delete_all
  end

  # Touching the row locks it until the block finishes
  def self.synchronize(key)
    transaction do
      where(key: key).touch_all # rubocop:disable Rails/SkipsModelValidations
      yield
    end
  end
end
