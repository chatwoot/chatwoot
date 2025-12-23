# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Devise
        module Patches
          # To avoid tracking new sessions that are created by
          # Rememberable strategy as Login Success events.
          module SkipSigninTrackingPatch
            def validate(*args)
              @_datadog_appsec_skip_track_login_event = true

              super
            end
          end
        end
      end
    end
  end
end
