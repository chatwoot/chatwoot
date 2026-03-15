# frozen_string_literal: true

# IgaraLead extensions — loaded after all controllers are defined.
# Keeping prepends here avoids modifying upstream Chatwoot controller files,
# which makes rebasing / merging with the official repo conflict-free.

require_relative '../../lib/omniauth/strategies/igarahub'

Rails.application.config.after_initialize do
  DeviseOverrides::OmniauthCallbacksController.prepend(Igaralead::OmniauthCallbacksExtension)
  DeviseOverrides::SessionsController.prepend(Igaralead::SessionsExtension)
  Account.prepend(Igaralead::AccountLimitsExtension)
  DashboardController.prepend(Igaralead::DashboardExtension)
end
