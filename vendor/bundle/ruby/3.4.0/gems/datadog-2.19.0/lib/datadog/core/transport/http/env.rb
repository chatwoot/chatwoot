# frozen_string_literal: true

module Datadog
  module Core
    module Transport
      module HTTP
        # Data structure for an HTTP request
        class Env < Hash
          attr_reader \
            :request

          # rubocop:disable Lint/MissingSuper
          def initialize(request, options = nil)
            @request = request
            merge!(options) unless options.nil?
          end
          # rubocop:enable Lint/MissingSuper

          def verb
            self[:verb]
          end

          def verb=(value)
            self[:verb] = value
          end

          def path
            self[:path]
          end

          def path=(value)
            self[:path] = value
          end

          def query
            self[:query]
          end

          def query=(value)
            self[:query] = value
          end

          def body
            self[:body]
          end

          def body=(value)
            self[:body] = value
          end

          def headers
            self[:headers] ||= {}
          end

          def headers=(value)
            self[:headers] = value
          end

          def form
            self[:form] ||= {}
          end

          def form=(value)
            self[:form] = value
          end
        end
      end
    end
  end
end
