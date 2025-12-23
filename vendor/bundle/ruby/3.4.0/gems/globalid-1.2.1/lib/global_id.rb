require 'active_support'
require 'global_id/global_id'

autoload :SignedGlobalID, 'global_id/signed_global_id'

class GlobalID
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Locator
    autoload :Identification
    autoload :Verifier
  end

  def self.eager_load!
    super
    require 'global_id/signed_global_id'
  end

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new("2.1", "GlobalID")
  end
end
