class EnqueueNativeCallPolicyJob < ActiveRecord::Migration[7.1]
  # Migrations run before the new processes take over, and an old one that connects an inbox
  # during the rollout still asks the connector to refuse calls. The wait lets the rollout
  # finish first.
  def up
    Migration::NativeCallPolicyJob.set(wait: 10.minutes).perform_later
  end

  def down; end
end
