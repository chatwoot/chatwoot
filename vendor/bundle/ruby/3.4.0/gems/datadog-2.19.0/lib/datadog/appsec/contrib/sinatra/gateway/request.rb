# frozen_string_literal: true

require_relative '../../rack/gateway/request'

module Datadog
  module AppSec
    module Contrib
      module Sinatra
        module Gateway
          # Gateway Request argument. Normalized extration of data from Rack::Request
          class Request < Rack::Gateway::Request
          end
        end
      end
    end
  end
end
