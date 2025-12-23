# frozen_string_literal: true

module Devise
  module Controllers
    # Custom Responder to configure default statuses that only apply to Devise,
    # and allow to integrate more easily with Hotwire/Turbo.
    class Responder < ActionController::Responder
      if respond_to?(:error_status=) && respond_to?(:redirect_status=)
        self.error_status = :ok
        self.redirect_status = :found
      else
        # TODO: remove this support for older Rails versions, which aren't supported by Turbo
        # and/or responders. It won't allow configuring a custom response, but it allows Devise
        # to use these methods and defaults across the implementation more easily.
        def self.error_status
          :ok
        end

        def self.redirect_status
          :found
        end

        def self.error_status=(*)
          warn "[DEVISE] Setting the error status on the Devise responder has no effect with this " \
            "version of `responders`, please make sure you're using a newer version. Check the changelog for more info."
        end

        def self.redirect_status=(*)
          warn "[DEVISE] Setting the redirect status on the Devise responder has no effect with this " \
            "version of `responders`, please make sure you're using a newer version. Check the changelog for more info."
        end
      end
    end
  end
end
