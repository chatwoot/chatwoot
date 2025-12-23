# frozen_string_literal: true

module Liquid
  class ParseTreeVisitor
    def self.for(node, callbacks = Hash.new(proc {}))
      if defined?(node.class::ParseTreeVisitor)
        node.class::ParseTreeVisitor
      else
        self
      end.new(node, callbacks)
    end

    def initialize(node, callbacks)
      @node      = node
      @callbacks = callbacks
    end

    def add_callback_for(*classes, &block)
      callback = block
      callback = ->(node, _) { yield node } if block.arity.abs == 1
      callback = ->(_, _) { yield } if block.arity.zero?
      classes.each { |klass| @callbacks[klass] = callback }
      self
    end

    def visit(context = nil)
      children.map do |node|
        item, new_context = @callbacks[node.class].call(node, context)
        [
          item,
          ParseTreeVisitor.for(node, @callbacks).visit(new_context || context),
        ]
      end
    end

    protected

    def children
      @node.respond_to?(:nodelist) ? Array(@node.nodelist) : []
    end
  end
end
