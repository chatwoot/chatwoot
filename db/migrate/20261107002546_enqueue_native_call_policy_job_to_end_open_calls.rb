class EnqueueNativeCallPolicyJobToEndOpenCalls < ActiveRecord::Migration[7.2]
  # The job now also ends the connector calls left open when calling was withdrawn, and an
  # install that already ran the previous enqueue needs it once more for that.
  def up
    Migration::NativeCallPolicyJob.set(wait: 10.minutes).perform_later
  end

  def down; end
end
