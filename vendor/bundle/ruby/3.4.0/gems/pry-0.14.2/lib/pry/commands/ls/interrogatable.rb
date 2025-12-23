# frozen_string_literal: true

class Pry
  class Command
    class Ls < Pry::ClassCommand
      module Interrogatable
        private

        def interrogating_a_module?
          Module === @interrogatee # rubocop:disable Style/CaseEquality
        end

        def interrogatee_mod
          if interrogating_a_module?
            @interrogatee
          else
            singleton = Pry::Method.singleton_class_of(@interrogatee)
            singleton.ancestors.grep(::Class).reject { |c| c == singleton }.first
          end
        end
      end
    end
  end
end
