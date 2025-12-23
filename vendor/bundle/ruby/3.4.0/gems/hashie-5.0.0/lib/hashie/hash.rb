require 'hashie/extensions/stringify_keys'
require 'hashie/extensions/pretty_inspect'

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  class Hash < ::Hash
    include Hashie::Extensions::PrettyInspect
    include Hashie::Extensions::StringifyKeys

    # Convert this hash into a Mash
    def to_mash
      ::Hashie::Mash.new(self)
    end

    # Converts a mash back to a hash (with stringified or symbolized keys)
    def to_hash(options = {})
      out = {}
      each_key do |k|
        assignment_key =
          if options[:stringify_keys]
            k.to_s
          elsif options[:symbolize_keys] && k.respond_to?(:to_sym)
            k.to_sym
          else
            k
          end
        if self[k].is_a?(Array)
          out[assignment_key] ||= []
          self[k].each do |array_object|
            out[assignment_key] << maybe_convert_to_hash(array_object, options)
          end
        else
          out[assignment_key] = maybe_convert_to_hash(self[k], options)
        end
      end
      out
    end

    # The C generator for the json gem doesn't like mashies
    def to_json(*args)
      to_hash.to_json(*args)
    end

    private

    def maybe_convert_to_hash(object, options)
      return object unless object.is_a?(Hash) || object.respond_to?(:to_hash)

      flexibly_convert_to_hash(object, options)
    end

    def flexibly_convert_to_hash(object, options = {})
      if object.method(:to_hash).arity.zero?
        object.to_hash
      else
        object.to_hash(options)
      end
    end
  end
end
