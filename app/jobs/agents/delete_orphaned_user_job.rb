class Agents::DeleteOrphanedUserJob < ApplicationJob
  queue_as :low

  def perform(user)
    # Checked at run time: the agent can be added back to an account while this job is queued.
    return if user.account_users.exists?

    user.destroy!
  end
end
