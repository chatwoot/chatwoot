# frozen_string_literal: true

module Net
  class IMAP
    class Config
      # >>>
      #   *NOTE:* The public methods on this module are part of the stable
      #   public API of Net::IMAP::Config.  But the module itself is an internal
      #   implementation detail, with no guarantee of backward compatibility.
      #
      # +attr_accessor+ methods will delegate to their #parent when the local
      # value does not contain an override.  Inheritance forms a singly linked
      # list, so lookup will be <tt>O(n)</tt> on the number of ancestors.  In
      # practice, the ancestor chain is not expected to be long.  Without
      # customization, it is only three deep:
      # >>>
      #     IMAP#config → Config.global → Config.default
      #
      # When creating a client with the +config+ keyword, for example to use
      # the appropriate defaults for an application or a library while still
      # relying on global for configuration of +debug+ or +logger+, most likely
      # the ancestor chain is still only four deep:
      # >>>
      #     IMAP#config → alternate defaults → Config.global → Config.default
      module AttrInheritance
        INHERITED = Module.new.freeze
        private_constant :INHERITED

        module Macros # :nodoc: internal API
          def attr_accessor(name) super; AttrInheritance.attr_accessor(name) end
        end
        private_constant :Macros

        def self.included(mod)
          mod.extend Macros
        end
        private_class_method :included

        def self.attr_accessor(name) # :nodoc: internal API
          module_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{name}; (val = super) == INHERITED ? parent&.#{name} : val end
          RUBY
        end

        # The parent Config object
        attr_reader :parent

        def initialize(parent = nil) # :notnew:
          super()
          @parent = Config[parent]
          reset
        end

        # Creates a new config, which inherits from +self+.
        def new(**attrs) self.class.new(self, **attrs) end

        # Returns +true+ if +attr+ is inherited from #parent and not overridden
        # by this config.
        def inherited?(attr) data[attr] == INHERITED end

        # :call-seq:
        #   reset -> self
        #   reset(attr) -> attribute value
        #
        # Resets an +attr+ to inherit from the #parent config.
        #
        # When +attr+ is nil or not given, all attributes are reset.
        def reset(attr = nil)
          if attr.nil?
            data.members.each do |attr| data[attr] = INHERITED end
            self
          elsif inherited?(attr)
            nil
          else
            old, data[attr] = data[attr], INHERITED
            old
          end
        end

        private

        def initialize_copy(other)
          super
          @parent ||= other # only default has nil parent
        end

      end
    end
  end
end
