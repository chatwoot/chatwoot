class BackfillRejectedCallStatus < ActiveRecord::Migration[7.1]
  def up
    execute("UPDATE calls SET status = 'rejected' WHERE status = 'failed' AND end_reason = 'agent_rejected'")
  end

  def down
    execute("UPDATE calls SET status = 'failed' WHERE status = 'rejected' AND end_reason = 'agent_rejected'")
  end
end
