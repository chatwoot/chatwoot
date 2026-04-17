# frozen_string_literal: true

# IgaraLead extensions — loaded after all controllers are defined.
# Keeping prepends here avoids modifying upstream Chatwoot controller files,
# which makes rebasing / merging with the official repo conflict-free.

Rails.application.config.after_initialize do
  DeviseOverrides::SessionsController.prepend(Igaralead::SessionsExtension)
  Account.prepend(Igaralead::AccountLimitsExtension)
  DashboardController.prepend(Igaralead::DashboardExtension)
end
