# frozen_string_literal: true

require_relative 'path'
require_relative 'digest'

module Datadog
  module Core
    module Remote
      class Configuration
        # TargetMap stores information regarding Configuration::Path and Configuration::Target
        class TargetMap < Hash
          class << self
            def parse(hash)
              opaque_backend_state = hash['signed']['custom']['opaque_backend_state']
              version = hash['signed']['version']

              map = new

              map.instance_eval do
                @opaque_backend_state = opaque_backend_state
                @version = version
              end

              hash['signed']['targets'].each_with_object(map) do |(p, t), m|
                path = Configuration::Path.parse(p)
                target = Configuration::Target.parse(t)

                m[path] = target
              end
            end
          end

          attr_reader :opaque_backend_state, :version

          def initialize
            super

            @opaque_backend_state = nil
            @version = nil
          end

          private_class_method :new
        end

        # Target stores digest information
        class Target
          class << self
            def parse(hash)
              length = Integer(hash['length'])
              digests = Configuration::DigestList.parse(hash['hashes'])
              version = Integer(hash['custom']['v'])

              new(digests: digests, length: length, version: version)
            end
          end

          attr_reader :length, :digests, :version

          def initialize(digests:, length:, version:)
            @digests = digests
            @length = length
            @version = version
          end

          private_class_method :new

          def check(content)
            digests.check(content)
          end
        end
      end
    end
  end
end
