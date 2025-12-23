# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Utility to assign a set of values to a constant
      module Sets
        REGISTRY = Hash.new do |h, set|
          name = Sets.name(set).freeze
          Sets.const_set(name, set)
          h[set] = "::RuboCop::AST::NodePattern::Sets::#{name}"
        end

        MAX = 4
        def self.name(set)
          elements = set
          elements = set.first(MAX - 1) << :etc if set.size > MAX
          name = elements.to_a.join('_').upcase.gsub(/[^A-Z0-9_]/, '')
          uniq("SET_#{name}")
        end

        def self.uniq(name)
          return name unless Sets.const_defined?(name)

          (2..Float::INFINITY).each do |i|
            uniq = "#{name}_#{i}"
            return uniq unless Sets.const_defined?(uniq)
          end
        end

        def self.[](set)
          REGISTRY[set]
        end
      end
    end
  end
end
