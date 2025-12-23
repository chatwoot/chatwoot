# frozen_string_literal: true

require_relative '../../../core/utils/only_once'

require_relative 'tracking_middleware'
require_relative 'patches/signup_tracking_patch'
require_relative 'patches/signin_tracking_patch'
require_relative 'patches/skip_signin_tracking_patch'

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Devise patcher
        module Patcher
          GUARD_ONCE_PER_APP = Hash.new do |hash, key|
            hash[key] = Datadog::Core::Utils::OnlyOnce.new
          end

          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            ::ActiveSupport.on_load(:before_initialize) do |app|
              GUARD_ONCE_PER_APP[app].run do
                app.middleware.insert_after(Warden::Manager, TrackingMiddleware)
              rescue RuntimeError
                AppSec.telemetry.error('AppSec: unable to insert Devise TrackingMiddleware')
              end
            end

            ::ActiveSupport.on_load(:after_initialize) do
              if ::Devise::RegistrationsController.descendants.empty?
                ::Devise::RegistrationsController.prepend(Patches::SignupTrackingPatch)
              else
                ::Devise::RegistrationsController.descendants.each do |controller|
                  controller.prepend(Patches::SignupTrackingPatch)
                end
              end
            end

            ::Devise::Strategies::Authenticatable.prepend(Patches::SigninTrackingPatch)

            if ::Devise::STRATEGIES.include?(:rememberable)
              # Rememberable strategy is required in autoloaded Rememberable model
              require 'devise/models/rememberable'
              ::Devise::Strategies::Rememberable.prepend(Patches::SkipSigninTrackingPatch)
            end

            Patcher.instance_variable_set(:@patched, true)
          end
        end
      end
    end
  end
end
