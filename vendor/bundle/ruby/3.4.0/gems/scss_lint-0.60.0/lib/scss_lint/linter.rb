module SCSSLint
  # Defines common functionality available to all linters.
  class Linter < Sass::Tree::Visitors::Base # rubocop:disable ClassLength
    include SelectorVisitor
    include Utils

    class << self
      attr_accessor :simple_name

      # When defining a Linter class, define its simple name as well. This
      # assumes that the module hierarchy of every linter starts with
      # `SCSSLint::Linter::`, and removes this part of the class name.
      #
      # `SCSSLint::Linter::Foo.simple_name`          #=> "Foo"
      # `SCSSLint::Linter::Compass::Bar.simple_name` #=> "Compass::Bar"
      def inherited(linter)
        name_parts = linter.name.split('::')
        name = name_parts.length < 3 ? '' : name_parts[2..-1].join('::')
        linter.simple_name = name
      end
    end

    attr_reader :config, :engine, :lints

    # Create a linter.
    def initialize
      @lints = []
    end

    # Run this linter against a parsed document with the given configuration,
    # returning the lints that were found.
    #
    # @param engine [Engine]
    # @param config [Config]
    # @return [Array<Lint>]
    def run(engine, config)
      @lints = []
      @config = config
      @engine = engine
      @comment_processor = ControlCommentProcessor.new(self)
      visit(engine.tree)
      @lints = @comment_processor.filter_lints(@lints)
    end

    # Return the human-friendly name of this linter as specified in the
    # configuration file and in lint descriptions.
    def name
      self.class.simple_name
    end

  protected

    # Helper for creating lint from a parse tree node
    #
    # @param node_or_line_or_location [Sass::Script::Tree::Node, Fixnum,
    #                                  SCSSLint::Location, Sass::Source::Position]
    # @param message [String]
    def add_lint(node_or_line_or_location, message)
      @lints << Lint.new(self,
                         engine.filename,
                         extract_location(node_or_line_or_location),
                         message,
                         @config.fetch('severity', :warning).to_sym)
    end

    # Extract {SCSSLint::Location} from a {Sass::Source::Range}.
    #
    # @param range [Sass::Source::Range]
    # @return [SCSSLint::Location]
    def location_from_range(range) # rubocop:disable Metrics/AbcSize
      length = if range.start_pos.line == range.end_pos.line
                 range.end_pos.offset - range.start_pos.offset
               else
                 line_source = engine.lines[range.start_pos.line - 1]
                 line_source.length - range.start_pos.offset + 1
               end

      # Workaround for https://github.com/sds/scss-lint/issues/887 to acount for
      # https://github.com/sass/sass/issues/2284.
      length = 1 if length < 1

      Location.new(range.start_pos.line, range.start_pos.offset, length)
    end

    # Extracts the original source code given a range.
    #
    # @param source_range [Sass::Source::Range]
    # @return [String] the original source code
    def source_from_range(source_range) # rubocop:disable Metrics/AbcSize
      current_line = source_range.start_pos.line - 1
      last_line    = source_range.end_pos.line - 1
      start_pos    = source_range.start_pos.offset - 1

      source =
        if current_line == last_line
          engine.lines[current_line][start_pos..(source_range.end_pos.offset - 1)]
        else
          engine.lines[current_line][start_pos..-1]
        end

      current_line += 1
      while current_line < last_line
        source += engine.lines[current_line].to_s
        current_line += 1
      end

      if source_range.start_pos.line != source_range.end_pos.line
        source += ((engine.lines[current_line] || '')[0...source_range.end_pos.offset]).to_s
      end

      source
    end

    # Returns whether a given node spans only a single line.
    #
    # @param node [Sass::Tree::Node]
    # @return [true,false] whether the node spans a single line
    def node_on_single_line?(node)
      return if node.source_range.start_pos.line != node.source_range.end_pos.line

      # The Sass parser reports an incorrect source range if the trailing curly
      # brace is on the next line, e.g.
      #
      #   p {
      #   }
      #
      # Since we don't want to count this as a single line node, check if the
      # last character on the first line is an opening curly brace.
      engine.lines[node.line - 1].strip[-1] != '{'
    end

    # Modified so we can also visit selectors in linters
    #
    # @param node [Sass::Tree::Node, Sass::Script::Tree::Node,
    #   Sass::Script::Value::Base]
    def visit(node)
      # Visit the selector of a rule if parsed rules are available
      if node.is_a?(Sass::Tree::RuleNode) && node.parsed_rules
        visit_selector(node.parsed_rules)
      end

      @comment_processor.before_node_visit(node) if @engine.any_control_commands
      super
      @comment_processor.after_node_visit(node) if @engine.any_control_commands
    end

    # Redefine so we can set the `node_parent` of each node
    #
    # @param parent [Sass::Tree::Node, Sass::Script::Tree::Node,
    #   Sass::Script::Value::Base]
    def visit_children(parent)
      parent.children.each do |child|
        child.node_parent = parent
        visit(child)
      end
    end

  private

    def visit_comment(_node)
      # Don't lint children of comments by default, as the Sass parser contains
      # many bugs related to the source ranges reported within code in /*...*/
      # comments.
      #
      # Instead of defining this empty method on every linter, we assume every
      # linter ignores comments by default. Individual linters can override at
      # their discretion.
    end

    def extract_location(node_or_line_or_location)
      if node_or_line_or_location.is_a?(Location)
        node_or_line_or_location
      elsif node_or_line_or_location.is_a?(Sass::Source::Position)
        Location.new(node_or_line_or_location.line, node_or_line_or_location.offset)
      elsif node_or_line_or_location.respond_to?(:source_range) &&
            node_or_line_or_location.source_range
        location_from_range(node_or_line_or_location.source_range)
      elsif node_or_line_or_location.respond_to?(:line)
        Location.new(node_or_line_or_location.line)
      else
        Location.new(node_or_line_or_location)
      end
    end

    # @param source_position [Sass::Source::Position]
    # @param offset [Integer]
    # @return [String] the character at the given [Sass::Source::Position]
    def character_at(source_position, offset = 0)
      actual_line   = source_position.line - 1
      actual_offset = source_position.offset + offset - 1

      return nil if actual_offset < 0

      engine.lines.size > actual_line && engine.lines[actual_line][actual_offset]
    end

    # Starting at source_position (plus offset), search for pattern and return
    # the offset from the source_position.
    #
    # @param source_position [Sass::Source::Position]
    # @param pattern [String, RegExp] the pattern to search for
    # @param offset [Integer]
    # @return [Integer] the offset at which [pattern] was found.
    def offset_to(source_position, pattern, offset = 0)
      actual_line   = source_position.line - 1
      actual_offset = source_position.offset + offset - 1

      return nil if actual_line >= engine.lines.size

      actual_index = engine.lines[actual_line].index(pattern, actual_offset)

      actual_index && actual_index + 1 - source_position.offset
    end
  end
end
