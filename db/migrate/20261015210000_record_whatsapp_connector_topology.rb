class RecordWhatsappConnectorTopology < ActiveRecord::Migration[7.1]
  # Synchronous on purpose: it is one pass over the keys, and a job enqueued here could be
  # picked up by a worker of the previous release, which does not have the class.
  def up
    Migration::WhatsappConnectorTopologyJob.perform_now
  end

  def down; end
end
