# frozen_string_literal: true

require 'json'

module Datadog
  module Core
    module Transport
      module HTTP
        module API
          # Endpoint
          class Endpoint
            attr_reader \
              :verb,
              :path

            def initialize(verb, path)
              @verb = verb
              @path = path
            end

            def call(env)
              env.verb = verb
              env.path = path
              yield(env)
            end
          end
        end
      end
    end
  end
end
