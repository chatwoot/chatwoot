# frozen_string_literal: true

module Haml
  # This class is used only internally. It holds the buffer of HTML that
  # is eventually output as the resulting document.
  # It's called from within the precompiled code,
  # and helps reduce the amount of processing done within `instance_eval`ed code.
  class Buffer
    include Haml::Helpers
    include Haml::Util

    # The string that holds the compiled HTML. This is aliased as
    # `_erbout` for compatibility with ERB-specific code.
    #
    # @return [String]
    attr_accessor :buffer

    # The options hash passed in from {Haml::Engine}.
    #
    # @return [{String => Object}]
    # @see Haml::Options#for_buffer
    attr_accessor :options

    # The {Buffer} for the enclosing Haml document.
    # This is set for partials and similar sorts of nested templates.
    # It's `nil` at the top level (see \{#toplevel?}).
    #
    # @return [Buffer]
    attr_accessor :upper

    # nil if there's no capture_haml block running,
    # and the position at which it's beginning the capture if there is one.
    #
    # @return [Fixnum, nil]
    attr_accessor :capture_position

    # @return [Boolean]
    # @see #active?
    attr_writer :active

    # @return [Boolean] Whether or not the format is XHTML
    def xhtml?
      not html?
    end

    # @return [Boolean] Whether or not the format is any flavor of HTML
    def html?
      html4? or html5?
    end

    # @return [Boolean] Whether or not the format is HTML4
    def html4?
      @options[:format] == :html4
    end

    # @return [Boolean] Whether or not the format is HTML5.
    def html5?
      @options[:format] == :html5
    end

    # @return [Boolean] Whether or not this buffer is a top-level template,
    #   as opposed to a nested partial
    def toplevel?
      upper.nil?
    end

    # Whether or not this buffer is currently being used to render a Haml template.
    # Returns `false` if a subtemplate is being rendered,
    # even if it's a subtemplate of this buffer's template.
    #
    # @return [Boolean]
    def active?
      @active
    end

    # @return [Fixnum] The current indentation level of the document
    def tabulation
      @real_tabs + @tabulation
    end

    # Sets the current tabulation of the document.
    #
    # @param val [Fixnum] The new tabulation
    def tabulation=(val)
      val = val - @real_tabs
      @tabulation = val > -1 ? val : 0
    end

    # @param upper [Buffer] The parent buffer
    # @param options [{Symbol => Object}] An options hash.
    #   See {Haml::Engine#options\_for\_buffer}
    def initialize(upper = nil, options = {})
      @active     = true
      @upper      = upper
      @options    = Options.buffer_defaults
      @options    = @options.merge(options) unless options.empty?
      @buffer     = new_encoded_string
      @tabulation = 0

      # The number of tabs that Engine thinks we should have
      # @real_tabs + @tabulation is the number of tabs actually output
      @real_tabs = 0
    end

    # Appends text to the buffer, properly tabulated.
    # Also modifies the document's indentation.
    #
    # @param text [String] The text to append
    # @param tab_change [Fixnum] The number of tabs by which to increase
    #   or decrease the document's indentation
    # @param dont_tab_up [Boolean] If true, don't indent the first line of `text`
    def push_text(text, tab_change, dont_tab_up)
      if @tabulation > 0
        # Have to push every line in by the extra user set tabulation.
        # Don't push lines with just whitespace, though,
        # because that screws up precompiled indentation.
        text.gsub!(/^(?!\s+$)/m, tabs)
        text.sub!(tabs, '') if dont_tab_up
      end

      @real_tabs += tab_change
      @buffer << text
    end

    # Modifies the indentation of the document.
    #
    # @param tab_change [Fixnum] The number of tabs by which to increase
    #   or decrease the document's indentation
    def adjust_tabs(tab_change)
      @real_tabs += tab_change
    end

    # Remove the whitespace from the right side of the buffer string.
    # Doesn't do anything if we're at the beginning of a capture_haml block.
    def rstrip!
      if capture_position.nil?
        buffer.rstrip!
        return
      end

      buffer << buffer.slice!(capture_position..-1).rstrip
    end

    # Works like #{find_and_preserve}, but allows the first newline after a
    # preserved opening tag to remain unencoded, and then outdents the content.
    # This change was motivated primarily by the change in Rails 3.2.3 to emit
    # a newline after textarea helpers.
    #
    # @param input [String] The text to process
    # @since Haml 4.0.1
    # @private
    def fix_textareas!(input)
      return input unless input.include?('<textarea'.freeze)

      pattern = /<(textarea)([^>]*)>(\n|&#x000A;)(.*?)<\/textarea>/im
      input.gsub!(pattern) do |s|
        match = pattern.match(s)
        content = match[4]
        if match[3] == '&#x000A;'
          content.sub!(/\A /, '&#x0020;')
        else
          content.sub!(/\A[ ]*/, '')
        end
        "<#{match[1]}#{match[2]}>\n#{content}</#{match[1]}>"
      end
      input
    end

    private

    def new_encoded_string
      "".encode(options[:encoding])
    end

    @@tab_cache = {}
    # Gets `count` tabs. Mostly for internal use.
    def tabs(count = 0)
      tabs = [count + @tabulation, 0].max
      @@tab_cache[tabs] ||= '  ' * tabs
    end
  end
end
