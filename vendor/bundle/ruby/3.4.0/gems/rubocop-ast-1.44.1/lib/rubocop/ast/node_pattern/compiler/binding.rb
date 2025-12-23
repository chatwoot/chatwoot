# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Holds the list of bound variable names
        class Binding
          def initialize
            @bound = {}
          end

          # Yields the first time a given name is bound
          #
          # @return [String] bound variable name
          def bind(name)
            var = @bound.fetch(name) do
              yield n = @bound[name] = "unify_#{name.gsub('-', '__')}"
              n
            end

            if var == :forbidden_unification
              raise Invalid, "Wildcard #{name} was first seen in a subset of a " \
                             "union and can't be used outside that union"
            end
            var
          end

          # Yields for each branch of the given union, forbidding unification of
          # bindings which only appear in a subset of the union.
          def union_bind(enum) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            # We need to reset @bound before each branch is processed.
            # Moreover we need to keep track of newly encountered wildcards.
            # Var `newly_bound_intersection` will hold those that are encountered
            # in all branches; these are not a problem.
            # Var `partially_bound` will hold those encountered in only a subset
            # of the branches; these can't be used outside of the union.

            return to_enum __method__, enum unless block_given?

            newly_bound_intersection = nil
            partially_bound = []
            bound_before = @bound.dup

            result = enum.each do |e|
              @bound = bound_before.dup if newly_bound_intersection
              yield e
              newly_bound = @bound.keys - bound_before.keys
              if newly_bound_intersection.nil?
                # First iteration
                newly_bound_intersection = newly_bound
              else
                union = newly_bound_intersection | newly_bound
                newly_bound_intersection &= newly_bound
                partially_bound |= union - newly_bound_intersection
              end
            end

            # At this point, all members of `newly_bound_intersection` can be used
            # for unification outside of the union, but partially_bound may not

            forbid(partially_bound)

            result
          end

          private

          def forbid(names)
            names.each do |name|
              @bound[name] = :forbidden_unification
            end
          end
        end
      end
    end
  end
end
