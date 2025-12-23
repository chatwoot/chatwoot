require "declarative/deep_dup"

module Declarative
  class Heritage < Array
    # Record inheritable assignments for replay in an inheriting class.
    def record(method, *args, &block)
      self << {method: method, args: DeepDup.(args), block: block} # DISCUSS: options.dup.
    end

    # Replay the recorded assignments on inheritor.
    # Accepts a block that will allow processing the arguments for every recorded statement.
    def call(inheritor, &block)
      each { |cfg| call!(inheritor, cfg, &block) }
    end

    module DSL
      def heritage
        @heritage ||= Heritage.new
      end
    end

    # To be extended into classes using Heritage. Inherits the heritage.
    module Inherited
      def inherited(subclass)
        super
        heritage.(subclass)
      end
    end

    # To be included into modules using Heritage. When included, inherits the heritage.
    module Included
      def included(mod)
        super
        heritage.(mod)
      end
    end

  private
    def call!(inheritor, cfg)
      yield cfg if block_given? # allow messing around with recorded arguments.

      inheritor.send(cfg[:method], *cfg[:args], &cfg[:block])
    end
  end
end
