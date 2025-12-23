module Declarative
  # {Defaults} is a mutable DSL object that collects default directives via #merge!.
  # Internally, it uses {Variables} to implement the merging of defaults.
  class Defaults
    def initialize
      @static_options  = {}
      @dynamic_options = ->(*) { {} }
    end

    # Set default values. Usually called in Schema::defaults.
    # This can be called multiple times and will "deep-merge" arrays, e.g. `_features: []`.
    def merge!(hash={}, &block)
      @static_options  = Variables.merge( @static_options, handle_array_and_deprecate(hash) )
      @dynamic_options = block if block_given?

      self
    end

    # Evaluate defaults and merge given_options into them.
    def call(name, given_options)
      # TODO: allow to receive rest of options/block in dynamic block. or, rather, test it as it was already implemented.
      evaluated_options = @dynamic_options.(name, given_options)

      options = Variables.merge( @static_options, handle_array_and_deprecate(evaluated_options) )
      Variables.merge( options, handle_array_and_deprecate(given_options) ) # FIXME: given_options is not tested!
    end

    def handle_array_and_deprecate(variables)
      wrapped = Defaults.wrap_arrays(variables)

      warn "[Declarative] Defaults#merge! and #call still accept arrays and automatically prepend those. This is now deprecated, you should replace `ary` with `Declarative::Variables::Append(ary)`." if wrapped.any?

      variables.merge(wrapped)
    end

    # Wrap arrays in `variables` with Variables::Append so they get appended to existing
    # same-named arrays.
    def self.wrap_arrays(variables)
      Hash[ variables.
        find_all { |k,v| v.instance_of?(Array) }.
        collect  { |k,v| [k, Variables::Append(v)] }
      ]
    end
  end
end
