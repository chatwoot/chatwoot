# Fork: the SECOND assignee-picker path.
#
# `GET /api/v1/accounts/:id/assignable_agents` does NOT call
# `Inbox#assignable_agents` — it rebuilds the list itself as
# `inbox members ∩ … + Current.account.administrators`
# (app/controllers/api/v1/accounts/assignable_agents_controller.rb:14). This is
# the endpoint the dashboard's own API client hits
# (app/javascript/dashboard/api/assignableAgents.js), so scoping only the model
# would have left the visible dropdown still offering the platform service admin.
#
# Unlike the other custom controllers, upstream ships no `prepend_mod_with` hook
# on this class, so the prepend is injected from
# config/initializers/custom_prepends.rb (net-new file, merge-safe).
module Custom
  module Api
    module V1
      module Accounts
        module AssignableAgentsController
          def index
            super
            @assignable_agents = Custom::PlatformManagedUsers.reject_from(
              @assignable_agents,
              Current.account
            )
          end
        end
      end
    end
  end
end
