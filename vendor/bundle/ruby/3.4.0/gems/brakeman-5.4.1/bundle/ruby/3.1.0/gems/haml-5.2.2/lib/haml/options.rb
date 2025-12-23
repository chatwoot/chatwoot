# frozen_string_literal: true

module Haml
  # This class encapsulates all of the configuration options that Haml
  # understands. Please see the {file:REFERENCE.md#options Haml Reference} to
  # learn how to set the options.
  class Options
    @valid_formats = [:html4, :html5, :xhtml]
    @buffer_option_keys = [:autoclose, :preserve, :attr_wrapper, :format,
      :encoding, :escape_html, :escape_filter_interpolations, :escape_attrs, :hyphenate_data_attrs, :cdata]

    class << self
      # The default option values.
      # @return Hash
      def defaults
        @defaults ||= Haml::TempleEngine.options.to_hash.merge(encoding: 'UTF-8')
      end

      # An array of valid values for the `:format` option.
      # @return Array
      attr_reader :valid_formats

      # An array of keys that will be used to provide a hash of options to
      # {Haml::Buffer}.
      # @return Hash
      attr_reader :buffer_option_keys

      # Returns a subset of defaults: those that {Haml::Buffer} cares about.
      # @return [{Symbol => Object}] The options hash
      def buffer_defaults
        @buffer_defaults ||= buffer_option_keys.inject({}) do |hash, key|
          hash.merge(key => defaults[key])
        end
      end

      def wrap(options)
        if options.is_a?(Options)
          options
        else
          Options.new(options)
        end
      end
    end

    # The character that should wrap element attributes. This defaults to `'`
    # (an apostrophe). Characters of this type within the attributes will be
    # escaped (e.g. by replacing them with `&apos;`) if the character is an
    # apostrophe or a quotation mark.
    attr_reader :attr_wrapper

    # A list of tag names that should be automatically self-closed if they have
    # no content. This can also contain regular expressions that match tag names
    # (or any object which responds to `#===`). Defaults to `['meta', 'img',
    # 'link', 'br', 'hr', 'input', 'area', 'param', 'col', 'base']`.
    attr_accessor :autoclose

    # The encoding to use for the HTML output.
    # This can be a string or an `Encoding` Object. Note that Haml **does not**
    # automatically re-encode Ruby values; any strings coming from outside the
    # application should be converted before being passed into the Haml
    # template. Defaults to `Encoding.default_internal`; if that's not set,
    # defaults to the encoding of the Haml template; if that's `US-ASCII`,
    # defaults to `"UTF-8"`.
    attr_reader :encoding

    # Sets whether or not to escape HTML-sensitive characters in attributes. If
    # this is true, all HTML-sensitive characters in attributes are escaped. If
    # it's set to false, no HTML-sensitive characters in attributes are escaped.
    # If it's set to `:once`, existing HTML escape sequences are preserved, but
    # other HTML-sensitive characters are escaped.
    #
    # Defaults to `true`.
    attr_accessor :escape_attrs

    # Sets whether or not to escape HTML-sensitive characters in script. If this
    # is true, `=` behaves like {file:REFERENCE.md#escaping_html `&=`};
    # otherwise, it behaves like {file:REFERENCE.md#unescaping_html `!=`}. Note
    # that if this is set, `!=` should be used for yielding to subtemplates and
    # rendering partials. See also {file:REFERENCE.md#escaping_html Escaping HTML} and
    # {file:REFERENCE.md#unescaping_html Unescaping HTML}.
    #
    # Defaults to false.
    attr_accessor :escape_html

    # Sets whether or not to escape HTML-sensitive characters in interpolated strings.
    # See also {file:REFERENCE.md#escaping_html Escaping HTML} and
    # {file:REFERENCE.md#unescaping_html Unescaping HTML}.
    #
    # Defaults to the current value of `escape_html`.
    attr_accessor :escape_filter_interpolations

    # The name of the Haml file being parsed.
    # This is only used as information when exceptions are raised. This is
    # automatically assigned when working through ActionView, so it's really
    # only useful for the user to assign when dealing with Haml programatically.
    attr_accessor :filename

    # If set to `true`, Haml will convert underscores to hyphens in all
    # {file:REFERENCE.md#html5_custom_data_attributes Custom Data Attributes} As
    # of Haml 4.0, this defaults to `true`.
    attr_accessor :hyphenate_data_attrs

    # The line offset of the Haml template being parsed. This is useful for
    # inline templates, similar to the last argument to `Kernel#eval`.
    attr_accessor :line

    # Determines the output format. The default is `:html5`. The other options
    # are `:html4` and `:xhtml`. If the output is set to XHTML, then Haml
    # automatically generates self-closing tags and wraps the output of the
    # Javascript and CSS-like filters inside CDATA. When the output is set to
    # `:html5` or `:html4`, XML prologs are ignored. In all cases, an appropriate
    # doctype is generated from `!!!`.
    #
    # If the mime_type of the template being rendered is `text/xml` then a
    # format of `:xhtml` will be used even if the global output format is set to
    # `:html4` or `:html5`.
    attr :format

    # The mime type that the rendered document will be served with. If this is
    # set to `text/xml` then the format will be overridden to `:xhtml` even if
    # it has set to `:html4` or `:html5`.
    attr_accessor :mime_type

    # A list of tag names that should automatically have their newlines
    # preserved using the {Haml::Helpers#preserve} helper. This means that any
    # content given on the same line as the tag will be preserved. For example,
    # `%textarea= "Foo\nBar"` compiles to `<textarea>Foo&#x000A;Bar</textarea>`.
    # Defaults to `['textarea', 'pre']`. See also
    # {file:REFERENCE.md#whitespace_preservation Whitespace Preservation}.
    attr_accessor :preserve

    # If set to `true`, all tags are treated as if both
    # {file:REFERENCE.md#whitespace_removal__and_ whitespace removal} options
    # were present. Use with caution as this may cause whitespace-related
    # formatting errors.
    #
    # Defaults to `false`.
    attr_accessor :remove_whitespace

    # Whether or not attribute hashes and Ruby scripts designated by `=` or `~`
    # should be evaluated. If this is `true`, said scripts are rendered as empty
    # strings.
    #
    # Defaults to `false`.
    attr_accessor :suppress_eval

    # Whether to include CDATA sections around javascript and css blocks when
    # using the `:javascript` or `:css` filters.
    #
    # This option also affects the `:sass`, `:scss`, `:less` and `:coffeescript`
    # filters.
    #
    # Defaults to `false` for html, `true` for xhtml. Cannot be changed when using
    # xhtml.
    attr_accessor :cdata

    # The parser class to use. Defaults to Haml::Parser.
    attr_accessor :parser_class

    # The compiler class to use. Defaults to Haml::Compiler.
    attr_accessor :compiler_class

    # Enable template tracing. If true, it will add a 'data-trace' attribute to
    # each tag generated by Haml. The value of the attribute will be the
    # source template name and the line number from which the tag was generated,
    # separated by a colon. On Rails applications, the path given will be a
    # relative path as from the views directory. On non-Rails applications,
    # the path will be the full path.
    attr_accessor :trace

    # Key is filter name in String and value is Class to use. Defaults to {}.
    attr_accessor :filters

    def initialize(values = {})
      defaults.each {|k, v| instance_variable_set :"@#{k}", v}
      values.each {|k, v| send("#{k}=", v) if defaults.has_key?(k) && !v.nil?}
      yield if block_given?
    end

    # Retrieve an option value.
    # @param key The value to retrieve.
    def [](key)
      send key
    end

    # Set an option value.
    # @param key The key to set.
    # @param value The value to set for the key.
    def []=(key, value)
      send "#{key}=", value
    end

    [:escape_attrs, :hyphenate_data_attrs, :remove_whitespace, :suppress_eval].each do |method|
      class_eval(<<-END)
        def #{method}?
          !! @#{method}
        end
      END
    end

    # @return [Boolean] Whether or not the format is XHTML.
    def xhtml?
      not html?
    end

    # @return [Boolean] Whether or not the format is any flavor of HTML.
    def html?
      html4? or html5?
    end

    # @return [Boolean] Whether or not the format is HTML4.
    def html4?
      format == :html4
    end

    # @return [Boolean] Whether or not the format is HTML5.
    def html5?
      format == :html5
    end

    def attr_wrapper=(value)
      @attr_wrapper = value || self.class.defaults[:attr_wrapper]
    end

    # Undef :format to suppress warning. It's defined above with the `:attr`
    # macro in order to make it appear in Yard's list of instance attributes.
    undef :format
    def format
      mime_type == "text/xml" ? :xhtml : @format
    end

    def format=(value)
      unless self.class.valid_formats.include?(value)
        raise Haml::Error, "Invalid output format #{value.inspect}"
      end
      @format = value
    end

    undef :cdata
    def cdata
      xhtml? || @cdata
    end

    def encoding=(value)
      return unless value
      @encoding = value.is_a?(Encoding) ? value.name : value.to_s
      @encoding = "UTF-8" if @encoding.upcase == "US-ASCII"
    end

    # Returns a non-default subset of options: those that {Haml::Buffer} cares about.
    # All of the values here are such that when `#inspect` is called on the hash,
    # it can be `Kernel#eval`ed to get the same result back.
    #
    # See {file:REFERENCE.md#options the Haml options documentation}.
    #
    # @return [{Symbol => Object}] The options hash
    def for_buffer
      self.class.buffer_option_keys.inject({}) do |hash, key|
        value = public_send(key)
        if self.class.buffer_defaults[key] != value
          hash[key] = value
        end
        hash
      end
    end

    private

    def defaults
      self.class.defaults
    end
  end
end
