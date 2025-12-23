# frozen_string_literal: true

require_relative '../../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        module ActionDispatch
          # Patcher for ActionController components
          module Patcher
            include Contrib::Patcher

            module_function

            def target_version
              Integration.version
            end

            def patch
              if ::ActionPack.gem_version >= Gem::Version.new('7.1')
                ::ActionDispatch::Journey::Router.prepend(ActionDispatch::Instrumentation::Journey::LazyRouter)
              else
                ::ActionDispatch::Journey::Router.prepend(ActionDispatch::Instrumentation::Journey::Router)
              end
            end
          end
        end
      end
    end
  end
end
