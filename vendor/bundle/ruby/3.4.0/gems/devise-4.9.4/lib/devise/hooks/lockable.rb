# frozen_string_literal: true

# After each sign in, if resource responds to failed_attempts, sets it to 0
# This is only triggered when the user is explicitly set (with set_user)
Warden::Manager.after_set_user except: :fetch do |record, warden, options|
  if record.respond_to?(:reset_failed_attempts!) && warden.authenticated?(options[:scope])
    record.reset_failed_attempts!
  end
end
