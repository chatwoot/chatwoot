# frozen_string_literal: true

# This is shamelessly borrowed from RuboCop RSpec
# https://github.com/rubocop-hq/rubocop-rspec/blob/master/lib/rubocop/rspec/language.rb
module RuboCop
  module Cop
    module RSpec
      # RSpec public API methods that are commonly used in cops
      module Language
        RSPEC = "{(const {nil? cbase} :RSpec) nil?}"

        # Set of method selectors
        class SelectorSet
          def initialize(selectors)
            @selectors = selectors
          end

          def ==(other)
            selectors.eql?(other.selectors)
          end

          def +(other)
            self.class.new(selectors + other.selectors)
          end

          def include?(selector)
            selectors.include?(selector)
          end

          def block_pattern
            "(block #{send_pattern} ...)"
          end

          def send_pattern
            "(send #{RSPEC} #{node_pattern_union} ...)"
          end

          def node_pattern_union
            "{#{node_pattern}}"
          end

          def node_pattern
            selectors.map(&:inspect).join(" ")
          end

          protected

          attr_reader :selectors
        end

        module ExampleGroups
          GROUPS = SelectorSet.new(%i[describe context feature example_group])
          SKIPPED = SelectorSet.new(%i[xdescribe xcontext xfeature])
          FOCUSED = SelectorSet.new(%i[fdescribe fcontext ffeature])

          ALL = GROUPS + SKIPPED + FOCUSED
        end

        module Examples
          EXAMPLES = SelectorSet.new(%i[it specify example scenario its])
          FOCUSED = SelectorSet.new(%i[fit fspecify fexample fscenario focus])
          SKIPPED = SelectorSet.new(%i[xit xspecify xexample xscenario skip])
          PENDING = SelectorSet.new(%i[pending])

          ALL = EXAMPLES + FOCUSED + SKIPPED + PENDING
        end

        module Runners
          ALL = SelectorSet.new(%i[to to_not not_to])
        end
      end
    end
  end
end
