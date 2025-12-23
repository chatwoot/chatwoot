# frozen_string_literal: true

module Aws
  module Endpoints
    # Does substitutions for templated endpoint strings

    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    module Templater
      class << self
        def resolve(string, parameters, assigns)
          # scans for strings in curly brackets {}
          string.scan(/\{.+?\}/).each do |capture|
            value = capture[1..-2] # strips curly brackets
            string = string.gsub(capture, replace(value, parameters, assigns))
          end
          string
        end

        private

        # Replaces the captured value with values from parameters or assign
        def replace(capture, parameters, assigns)
          # Pound sigil is used for getAttr calls
          indexes = capture.split('#')

          # no sigil found, just do substitution
          if indexes.size == 1
            extract_value(capture, parameters, assigns)
          # sigil was found, need to call getAttr
          elsif indexes.size == 2
            ref, property = indexes
            param = extract_value(ref, parameters, assigns)
            Matchers.attr(param, property)
          else
            raise "Invalid templatable value: #{capture}"
          end
        end

        # Checks both parameters and assigns hash for the referenced value
        def extract_value(key, parameters, assigns)
          if assigns.key?(key)
            assigns[key]
          elsif parameters.class.singleton_class::PARAM_MAP.key?(key)
            member_name = parameters.class.singleton_class::PARAM_MAP[key]
            parameters[member_name]
          else
            raise "Templatable value not found: #{key}"
          end
        end
      end
    end
  end
end
