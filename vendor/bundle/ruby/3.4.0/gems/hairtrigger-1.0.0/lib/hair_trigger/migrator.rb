module HairTrigger
  module Migrator
    class << self
      module ProperTableNameWithHashAwarenessSupport
        def proper_table_name(*args)
          name = args.first
          return name if name.is_a?(Hash)
          super
        end
      end

      def extended(base)
        base.class_eval do
          class << self
            prepend ProperTableNameWithHashAwarenessSupport
          end
        end
      end

      def included(base)
        base.instance_eval do
          prepend ProperTableNameWithHashAwarenessSupport
        end
      end
    end
  end
end
