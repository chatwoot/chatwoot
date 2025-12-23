# frozen_string_literal: true

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* This module is an internal implementation detail, with no
      #   guarantee of backward compatibility.
      #
      # Adds a +type+ keyword parameter to +attr_accessor+, to enforce that
      # config attributes have valid types, for example: boolean, numeric,
      # enumeration, non-nullable, etc.
      module AttrTypeCoercion
        # :stopdoc: internal APIs only

        module Macros # :nodoc: internal API
          def attr_accessor(attr, type: nil)
            super(attr)
            AttrTypeCoercion.attr_accessor(attr, type: type)
          end

          module_function def Integer?; NilOrInteger end
        end
        private_constant :Macros

        def self.included(mod)
          mod.extend Macros
        end
        private_class_method :included

        if defined?(Ractor.make_shareable)
          def self.safe(...) Ractor.make_shareable nil.instance_eval(...).freeze end
        else
          def self.safe(...) nil.instance_eval(...).freeze end
        end
        private_class_method :safe

        Types = Hash.new do |h, type|
          type.nil? || Proc === type or raise TypeError, "type not nil or Proc"
          safe{type}
        end
        Types[:boolean] = Boolean = safe{-> {!!_1}}
        Types[Integer]  = safe{->{Integer(_1)}}

        def self.attr_accessor(attr, type: nil)
          type = Types[type] or return
          define_method :"#{attr}=" do |val| super type[val] end
          define_method :"#{attr}?" do send attr end if type == Boolean
        end

        NilOrInteger = safe{->val { Integer val unless val.nil? }}

        Enum = ->(*enum) {
          enum     = safe{enum}
          expected = -"one of #{enum.map(&:inspect).join(", ")}"
          safe{->val {
            return val if enum.include?(val)
            raise ArgumentError, "expected %s, got %p" % [expected, val]
          }}
        }

      end
    end
  end
end
