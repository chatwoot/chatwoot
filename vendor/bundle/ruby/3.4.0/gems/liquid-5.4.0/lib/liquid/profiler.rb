# frozen_string_literal: true

require 'liquid/profiler/hooks'

module Liquid
  # Profiler enables support for profiling template rendering to help track down performance issues.
  #
  # To enable profiling, first require 'liquid/profiler'.
  # Then, to profile a parse/render cycle, pass the <tt>profile: true</tt> option to <tt>Liquid::Template.parse</tt>.
  # After <tt>Liquid::Template#render</tt> is called, the template object makes available an instance of this
  # class via the <tt>Liquid::Template#profiler</tt> method.
  #
  #   template = Liquid::Template.parse(template_content, profile: true)
  #   output  = template.render
  #   profile = template.profiler
  #
  # This object contains all profiling information, containing information on what tags were rendered,
  # where in the templates these tags live, and how long each tag took to render.
  #
  # This is a tree structure that is Enumerable all the way down, and keeps track of tags and rendering times
  # inside of <tt>{% include %}</tt> tags.
  #
  #   profile.each do |node|
  #     # Access to the node itself
  #     node.code
  #
  #     # Which template and line number of this node.
  #     # The top-level template name is `nil` by default, but can be set in the Liquid::Context before rendering.
  #     node.partial
  #     node.line_number
  #
  #     # Render time in seconds of this node
  #     node.render_time
  #
  #     # If the template used {% include %}, this node will also have children.
  #     node.children.each do |child2|
  #       # ...
  #     end
  #   end
  #
  # Profiler also exposes the total time of the template's render in <tt>Liquid::Profiler#total_render_time</tt>.
  #
  # All render times are in seconds. There is a small performance hit when profiling is enabled.
  #
  class Profiler
    include Enumerable

    class Timing
      attr_reader :code, :template_name, :line_number, :children
      attr_accessor :total_time
      alias_method :render_time, :total_time
      alias_method :partial, :template_name

      def initialize(code: nil, template_name: nil, line_number: nil)
        @code = code
        @template_name = template_name
        @line_number = line_number
        @children = []
      end

      def self_time
        @self_time ||= begin
          total_children_time = 0.0
          @children.each do |child|
            total_children_time += child.total_time
          end
          @total_time - total_children_time
        end
      end
    end

    attr_reader :total_time
    alias_method :total_render_time, :total_time

    def initialize
      @root_children = []
      @current_children = nil
      @total_time = 0.0
    end

    def profile(template_name, &block)
      # nested renders are done from a tag that already has a timing node
      return yield if @current_children

      root_children = @root_children
      render_idx = root_children.length
      begin
        @current_children = root_children
        profile_node(template_name, &block)
      ensure
        @current_children = nil
        if (timing = root_children[render_idx])
          @total_time += timing.total_time
        end
      end
    end

    def children
      children = @root_children
      if children.length == 1
        children.first.children
      else
        children
      end
    end

    def each(&block)
      children.each(&block)
    end

    def [](idx)
      children[idx]
    end

    def length
      children.length
    end

    def profile_node(template_name, code: nil, line_number: nil)
      timing = Timing.new(code: code, template_name: template_name, line_number: line_number)
      parent_children = @current_children
      start_time = monotonic_time
      begin
        @current_children = timing.children
        yield
      ensure
        @current_children = parent_children
        timing.total_time = monotonic_time - start_time
        parent_children << timing
      end
    end

    private

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
