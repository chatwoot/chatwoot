# frozen_string_literal: true

require 'sucker_punch'

module Datadog
  module Tracing
    module Contrib
      module SuckerPunch
        # Patches `sucker_punch` exception handling
        module ExceptionHandler
          METHOD = ->(e, *) { raise(e) }

          module_function

          def patch!
            ::SuckerPunch.singleton_class.class_eval do
              alias_method :__exception_handler, :exception_handler

              def exception_handler
                ::Datadog::Tracing::Contrib::SuckerPunch::ExceptionHandler::METHOD
              end
            end
          end
        end
      end
    end
  end
end
