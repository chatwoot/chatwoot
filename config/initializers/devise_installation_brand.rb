# frozen_string_literal: true

# Devise::Mailer inherits from ApplicationMailer (config.parent_mailer), so it would otherwise
# pick up the brand of whatever account is in Current -- and User#send_devise_notification
# falls back to `accounts.first` when there is none, which for a user in several workspaces is
# whichever row the database returns. These three are credentials of the person on this
# installation, so they stay on the installation's brand.
#
# confirmation_instructions is deliberately absent: it doubles as the workspace invitation,
# whose own template names the account, the inviter and the workspace being joined.
Rails.application.config.to_prepare do
  Devise::Mailer.installation_branded!(:reset_password_instructions, :password_change, :unlock_instructions)
end
