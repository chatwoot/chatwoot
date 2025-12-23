# frozen_string_literal: true

require "commonmarker/node/inspect"

module CommonMarker
  class Node
    include Enumerable
    include Inspect

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&block)
      return enum_for(:walk) unless block

      yield self
      each do |child|
        child.walk(&block)
      end
    end

    # Public: Convert the node to an HTML string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # extensions - An {Array of Symbol}s indicating the extensions to use
    #
    # Returns a {String}.
    def to_html(options = :DEFAULT, extensions = [])
      opts = Config.process_options(options, :render)
      _render_html(opts, extensions).force_encoding("utf-8")
    end

    # Public: Convert the node to an XML string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    #
    # Returns a {String}.
    def to_xml(options = :DEFAULT)
      opts = Config.process_options(options, :render)
      _render_xml(opts).force_encoding("utf-8")
    end

    # Public: Convert the node to a CommonMark string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # width - Column to wrap the output at
    #
    # Returns a {String}.
    def to_commonmark(options = :DEFAULT, width = 120)
      opts = Config.process_options(options, :render)
      _render_commonmark(opts, width).force_encoding("utf-8")
    end

    # Public: Convert the node to a plain text string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    # width - Column to wrap the output at
    #
    # Returns a {String}.
    def to_plaintext(options = :DEFAULT, width = 120)
      opts = Config.process_options(options, :render)
      _render_plaintext(opts, width).force_encoding("utf-8")
    end

    # Public: Iterate over the children (if any) of the current pointer.
    def each
      return enum_for(:each) unless block_given?

      child = first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end

    # Deprecated: Please use `each` instead
    def each_child(&block)
      warn("[DEPRECATION] `each_child` is deprecated.  Please use `each` instead.")
      each(&block)
    end
  end
end
