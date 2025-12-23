# frozen_string_literal: true

require_relative '../../../instrumentation/gateway/argument'

module Datadog
  module AppSec
    module Contrib
      module Sinatra
        module Gateway
          # Gateway Route Params argument.
          class RouteParams < Instrumentation::Gateway::Argument
            attr_reader :params

            def initialize(params)
              super()
              @params = params
            end
          end
        end
      end
    end
  end
end
