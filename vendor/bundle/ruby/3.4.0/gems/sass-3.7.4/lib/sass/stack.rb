module Sass
  # A class representing the stack when compiling a Sass file.
  class Stack
    # TODO: use this to generate stack information for Sass::SyntaxErrors.

    # A single stack frame.
    class Frame
      # The filename of the file in which this stack frame was created.
      #
      # @return [String]
      attr_reader :filename

      # The line number on which this stack frame was created.
      #
      # @return [String]
      attr_reader :line

      # The type of this stack frame. This can be `:import`, `:mixin`, or
      # `:base`.
      #
      # `:base` indicates that this is the bottom-most frame, meaning that it
      # represents a single line of code rather than a nested context. The stack
      # will only ever have one base frame, and it will always be the most
      # deeply-nested frame.
      #
      # @return [Symbol?]
      attr_reader :type

      # The name of the stack frame. For mixin frames, this is the mixin name;
      # otherwise, it's `nil`.
      #
      # @return [String?]
      attr_reader :name

      def initialize(filename, line, type, name = nil)
        @filename = filename
        @line = line
        @type = type
        @name = name
      end

      # Whether this frame represents an import.
      #
      # @return [Boolean]
      def is_import?
        type == :import
      end

      # Whether this frame represents a mixin.
      #
      # @return [Boolean]
      def is_mixin?
        type == :mixin
      end

      # Whether this is the base frame.
      #
      # @return [Boolean]
      def is_base?
        type == :base
      end
    end

    # The stack frames. The last frame is the most deeply-nested.
    #
    # @return [Array<Frame>]
    attr_reader :frames

    def initialize
      @frames = []
    end

    # Pushes a base frame onto the stack.
    #
    # @param filename [String] See \{Frame#filename}.
    # @param line [String] See \{Frame#line}.
    # @yield [] A block in which the new frame is on the stack.
    def with_base(filename, line)
      with_frame(filename, line, :base) {yield}
    end

    # Pushes an import frame onto the stack.
    #
    # @param filename [String] See \{Frame#filename}.
    # @param line [String] See \{Frame#line}.
    # @yield [] A block in which the new frame is on the stack.
    def with_import(filename, line)
      with_frame(filename, line, :import) {yield}
    end

    # Pushes a mixin frame onto the stack.
    #
    # @param filename [String] See \{Frame#filename}.
    # @param line [String] See \{Frame#line}.
    # @param name [String] See \{Frame#name}.
    # @yield [] A block in which the new frame is on the stack.
    def with_mixin(filename, line, name)
      with_frame(filename, line, :mixin, name) {yield}
    end

    # Pushes a function frame onto the stack.
    #
    # @param filename [String] See \{Frame#filename}.
    # @param line [String] See \{Frame#line}.
    # @param name [String] See \{Frame#name}.
    # @yield [] A block in which the new frame is on the stack.
    def with_function(filename, line, name)
      with_frame(filename, line, :function, name) {yield}
    end

    # Pushes a function frame onto the stack.
    #
    # @param filename [String] See \{Frame#filename}.
    # @param line [String] See \{Frame#line}.
    # @param name [String] See \{Frame#name}.
    # @yield [] A block in which the new frame is on the stack.
    def with_directive(filename, line, name)
      with_frame(filename, line, :directive, name) {yield}
    end

    def to_s
      (frames.reverse + [nil]).each_cons(2).each_with_index.
          map do |(frame, caller), i|
        "#{i == 0 ? 'on' : 'from'} line #{frame.line}" +
          " of #{frame.filename || 'an unknown file'}" +
          (caller && caller.name ? ", in `#{caller.name}'" : "")
      end.join("\n")
    end

    private

    def with_frame(filename, line, type, name = nil)
      @frames.pop if @frames.last && @frames.last.type == :base
      @frames.push(Frame.new(filename, line, type, name))
      yield
    ensure
      @frames.pop unless type == :base && @frames.last && @frames.last.type != :base
    end
  end
end
