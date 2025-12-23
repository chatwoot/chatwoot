# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for a rescued exception that get shadowed by a
      # less specific exception being rescued before a more specific
      # exception is rescued.
      #
      # An exception is considered shadowed if it is rescued after its
      # ancestor is, or if it and its ancestor are both rescued in the
      # same `rescue` statement. In both cases, the more specific rescue is
      # unnecessary because it is covered by rescuing the less specific
      # exception. (ie. `rescue Exception, StandardError` has the same behavior
      # whether `StandardError` is included or not, because all ``StandardError``s
      # are rescued by `rescue Exception`).
      #
      # @example
      #
      #   # bad
      #
      #   begin
      #     something
      #   rescue Exception
      #     handle_exception
      #   rescue StandardError
      #     handle_standard_error
      #   end
      #
      #   # bad
      #   begin
      #     something
      #   rescue Exception, StandardError
      #     handle_error
      #   end
      #
      #   # good
      #
      #   begin
      #     something
      #   rescue StandardError
      #     handle_standard_error
      #   rescue Exception
      #     handle_exception
      #   end
      #
      #   # good, however depending on runtime environment.
      #   #
      #   # This is a special case for system call errors.
      #   # System dependent error code depends on runtime environment.
      #   # For example, whether `Errno::EAGAIN` and `Errno::EWOULDBLOCK` are
      #   # the same error code or different error code depends on environment.
      #   # This good case is for `Errno::EAGAIN` and `Errno::EWOULDBLOCK` with
      #   # the same error code.
      #   begin
      #     something
      #   rescue Errno::EAGAIN, Errno::EWOULDBLOCK
      #     handle_standard_error
      #   end
      #
      class ShadowedException < Base
        include RescueNode
        include RangeHelp

        MSG = 'Do not shadow rescued Exceptions.'

        def on_rescue(node)
          return if rescue_modifier?(node)

          rescues = node.resbody_branches
          rescued_groups = rescued_groups_for(rescues)

          rescue_group_rescues_multiple_levels = rescued_groups.any? do |group|
            contains_multiple_levels_of_exceptions?(group)
          end

          return if !rescue_group_rescues_multiple_levels && sorted?(rescued_groups)

          add_offense(offense_range(rescues))
        end

        private

        def offense_range(rescues)
          shadowing_rescue = find_shadowing_rescue(rescues)
          expression = shadowing_rescue.source_range
          range_between(expression.begin_pos, expression.end_pos)
        end

        def rescued_groups_for(rescues)
          rescues.map { |group| evaluate_exceptions(group) }
        end

        def contains_multiple_levels_of_exceptions?(group)
          # Always treat `Exception` as the highest level exception.
          return true if group.size > 1 && group.include?(Exception)

          group.combination(2).any? { |a, b| compare_exceptions(a, b) }
        end

        def compare_exceptions(exception, other_exception)
          if system_call_err?(exception) && system_call_err?(other_exception)
            # This condition logic is for special case.
            # System dependent error code depends on runtime environment.
            # For example, whether `Errno::EAGAIN` and `Errno::EWOULDBLOCK` are
            # the same error code or different error code depends on runtime
            # environment. This checks the error code for that.
            exception.const_get(:Errno) != other_exception.const_get(:Errno) &&
              exception <=> other_exception
          else
            exception && other_exception && exception <=> other_exception
          end
        end

        def system_call_err?(error)
          error && error.ancestors[1] == SystemCallError
        end

        def evaluate_exceptions(group)
          rescued_exceptions = group.exceptions

          if rescued_exceptions.any?
            rescued_exceptions.each_with_object([]) do |exception, converted|
              RuboCop::Util.silence_warnings do
                # Avoid printing deprecation warnings about constants
                converted << Kernel.const_get(exception.source)
              end
            rescue NameError
              converted << nil
            end
          else
            # treat an empty `rescue` as `rescue StandardError`
            [StandardError]
          end
        end

        def sorted?(rescued_groups)
          rescued_groups.each_cons(2).all? do |x, y|
            if x.include?(Exception)
              false
            elsif y.include?(Exception) ||
                  # consider sorted if a group is empty or only contains
                  # `nil`s
                  x.none? || y.none?
              true
            else
              (x <=> y || 0) <= 0
            end
          end
        end

        def find_shadowing_rescue(rescues)
          rescued_groups = rescued_groups_for(rescues)
          rescued_groups.zip(rescues).each do |group, res|
            return res if contains_multiple_levels_of_exceptions?(group)
          end

          rescued_groups.each_cons(2).with_index do |group_pair, i|
            return rescues[i] unless sorted?(group_pair)
          end
        end
      end
    end
  end
end
