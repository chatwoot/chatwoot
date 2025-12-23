require 'active_support/testing/time_helpers'

require 'devise_two_factor/spec_helpers/two_factor_authenticatable_shared_examples'
require 'devise_two_factor/spec_helpers/two_factor_backupable_shared_examples'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
