module Declarative
  # Implements the pattern of maintaining a hash of key/values (usually "defaults")
  # that are mutated several times by user and library code (override defaults).
  #
  # The Variables instance then represents the configuration data to be processed by the
  # using library (e.g. Representable or Trailblazer).
  class Variables
    class Proc < ::Proc
    end

    # @return Hash hash where `overrides` is merged onto `defaults` respecting Merge, Append etc.
    def self.merge(defaults, overrides)
      defaults = defaults.merge({}) # todo: use our DeepDup. # TODO: or how could we provide immutability?

      overrides.each do |k, v|
        if v.is_a?(Variables::Proc)
          defaults[k] = v.( defaults[k] )
        else
          defaults[k] = v
        end
      end

      defaults
    end

    def self.Merge(merged_hash)
      Variables::Proc.new do |original|
        (original || {}).merge( merged_hash )
      end
    end

    def self.Append(appended_array)
      Variables::Proc.new do |original|
        (original || []) + appended_array
      end
    end
  end # Variables
end
