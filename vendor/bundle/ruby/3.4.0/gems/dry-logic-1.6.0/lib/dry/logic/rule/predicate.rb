# frozen_string_literal: true

module Dry
  module Logic
    class Rule
      class Predicate < Rule
        def self.specialize(arity, curried, base = Predicate)
          super
        end

        def type
          :predicate
        end

        def name
          predicate.name
        end

        def to_s
          if args.empty?
            name.to_s
          else
            "#{name}(#{args.map(&:inspect).join(", ")})"
          end
        end

        def ast(input = Undefined)
          [type, [name, args_with_names(input)]]
        end
        alias_method :to_ast, :ast
      end
    end
  end
end
