# frozen_string_literal: true

class Pry
  module Testable
    module Evalable
      def pry_tester(*args, &block)
        args.unshift(Pry.toplevel_binding) if args.empty? || args[0].is_a?(Hash)
        Pry::Testable::PryTester.new(*args).tap do |t|
          t.singleton_class.class_eval(&block) if block
        end
      end

      def pry_eval(*eval_strs)
        b =
          if eval_strs.first.is_a?(String)
            Pry.toplevel_binding
          else
            Pry.binding_for(eval_strs.shift)
          end
        pry_tester(b).eval(*eval_strs)
      end
    end
  end
end
