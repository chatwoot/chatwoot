# frozen_string_literal: true

require_relative '../../../encoding'
require_relative '../../../transport/http/api/map'
require_relative '../../../transport/http/api/instance'
require_relative '../../../transport/http/api/spec'
require_relative 'negotiation'
require_relative 'config'

module Datadog
  module Core
    module Remote
      module Transport
        module HTTP
          # Namespace for API components
          module API
            # Default API versions
            ROOT = 'root'
            V7 = 'v0.7'

            module_function

            def defaults
              Core::Transport::HTTP::API::Map[
                ROOT => Spec.new do |s|
                  s.info = Negotiation::API::Endpoint.new(
                    '/info',
                  )
                end,
                V7 => Spec.new do |s|
                  s.config = Config::API::Endpoint.new(
                    '/v0.7/config',
                    Core::Encoding::JSONEncoder,
                  )
                end,
              ]
            end

            class Instance < Core::Transport::HTTP::API::Instance
              include Config::API::Instance
              include Negotiation::API::Instance
            end

            class Spec < Core::Transport::HTTP::API::Spec
              include Config::API::Spec
              include Negotiation::API::Spec
            end
          end
        end
      end
    end
  end
end
