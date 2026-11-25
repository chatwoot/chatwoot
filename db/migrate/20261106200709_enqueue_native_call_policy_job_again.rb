class EnqueueNativeCallPolicyJobAgain < ActiveRecord::Migration[7.2]
  # Calling through the connector was withdrawn, and an inbox connected with calling on keeps
  # that policy on the connector until it is connected again. The wait lets the rollout finish
  # first, so the connect goes out from the new processes.
  def up
    Migration::NativeCallPolicyJob.set(wait: 10.minutes).perform_later
  end

  def down; end
end
