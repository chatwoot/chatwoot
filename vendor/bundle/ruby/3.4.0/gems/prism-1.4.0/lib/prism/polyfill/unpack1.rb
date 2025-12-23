# frozen_string_literal: true

# Polyfill for String#unpack1 with the offset parameter. Not all Ruby engines
# have Method#parameters implemented, so we check the arity instead if
# necessary.
if (unpack1 = String.instance_method(:unpack1)).respond_to?(:parameters) ? unpack1.parameters.none? { |_, name| name == :offset } : (unpack1.arity == 1)
  String.prepend(
    Module.new {
      def unpack1(format, offset: 0) # :nodoc:
        offset == 0 ? super(format) : self[offset..].unpack1(format) # steep:ignore
      end
    }
  )
end
