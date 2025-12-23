# frozen_string_literal: true

module Datadog
  module Core
    module Remote
      class Configuration
        # Path stores path information
        class Path
          class ParseError < StandardError; end

          class << self
            RE = %r{
              ^
              (?<source>
                datadog/(?<org_id>\d+)
                |
                employee
              )
              /
              (?<product>[^/]+)
              /
              (?<config_id>[^/]+)
              /
              (?<name>[^/]+)
              $
            }mx.freeze

            def parse(path)
              m = RE.match(path)

              raise ParseError, "could not parse: #{path.inspect}" if m.nil?

              org_id = m['org_id']&.to_i

              source = m['source']
              raise ParseError, 'missing source value' unless source

              source = source.delete("/#{org_id}") if org_id

              product = m['product']
              raise ParseError, 'missing product value' unless product

              config_id = m['config_id']
              raise ParseError, 'missing config_id value' unless config_id

              name = m['name']
              raise ParseError, 'missing name value' unless name

              new(source: source, org_id: org_id, product: product, config_id: config_id, name: name)
            end
          end

          attr_reader :source, :org_id, :product, :config_id, :name

          def initialize(source:, product:, config_id:, name:, org_id: nil)
            @source = source
            @org_id = org_id
            @product = product
            @config_id = config_id
            @name = name
          end

          private_class_method :new

          def to_s
            if org_id
              "#{source}/#{org_id}/#{product}/#{config_id}/#{name}"
            else
              "#{source}/#{product}/#{config_id}/#{name}"
            end
          end

          def ==(other)
            return false unless other.is_a?(Path)

            to_s == other.to_s
          end

          def hash
            to_s.hash
          end

          def eql?(other)
            hash == other.hash
          end
        end
      end
    end
  end
end
