# frozen_string_literal: true
module Tilt
  # @private
  module CompiledTemplates
  end

  # @private
  TOPOBJECT = CompiledTemplates

  # @private
  LOCK = Mutex.new

  # Base class for template implementations. Subclasses must implement
  # the #prepare method and one of the #evaluate or #precompiled_template
  # methods.
  class Template
    # Template source; loaded from a file or given directly.
    attr_reader :data

    # The name of the file where the template data was loaded from.
    attr_reader :file

    # The line number in #file where template data was loaded from.
    attr_reader :line

    # A Hash of template engine specific options. This is passed directly
    # to the underlying engine and is not used by the generic template
    # interface.
    attr_reader :options

    # A path ending in .rb that the template code will be written to, then
    # required, instead of being evaled.  This is useful for determining
    # coverage of compiled template code, or to use static analysis tools
    # on the compiled template code.
    attr_reader :compiled_path

    class << self
      # An empty Hash that the template engine can populate with various
      # metadata.
      def metadata
        @metadata ||= {}
      end

      # Use `.metadata[:mime_type]` instead.
      def default_mime_type
        metadata[:mime_type]
      end

      # Use `.metadata[:mime_type] = val` instead.
      def default_mime_type=(value)
        metadata[:mime_type] = value
      end
    end

    # Create a new template with the file, line, and options specified. By
    # default, template data is read from the file. When a block is given,
    # it should read template data and return as a String. When file is nil,
    # a block is required.
    #
    # All arguments are optional.
    def initialize(file=nil, line=nil, options=nil)
      @file, @line, @options = nil, 1, nil

      process_arg(options)
      process_arg(line)
      process_arg(file)

      raise ArgumentError, "file or block required" unless @file || block_given?

      @options ||= {}

      set_compiled_method_cache

      # Force the encoding of the input data
      @default_encoding = @options.delete :default_encoding

      # Skip encoding detection from magic comments and forcing that encoding
      # for compiled templates
      @skip_compiled_encoding_detection = @options.delete :skip_compiled_encoding_detection

      # load template data and prepare (uses binread to avoid encoding issues)
      @data = block_given? ? yield(self) : read_template_file

      if @data.respond_to?(:force_encoding)
        if default_encoding
          @data = @data.dup if @data.frozen?
          @data.force_encoding(default_encoding)
        end

        if !@data.valid_encoding?
          raise Encoding::InvalidByteSequenceError, "#{eval_file} is not valid #{@data.encoding}"
        end
      end

      prepare
    end

    # Render the template in the given scope with the locals specified. If a
    # block is given, it is typically available within the template via
    # +yield+.
    def render(scope=nil, locals=nil, &block)
      evaluate(scope || Object.new, locals || EMPTY_HASH, &block)
    end

    # The basename of the template file.
    def basename(suffix='')
      File.basename(@file, suffix) if @file
    end

    # The template file's basename with all extensions chomped off.
    def name
      if bname = basename
        bname.split('.', 2).first
      end
    end

    # The filename used in backtraces to describe the template.
    def eval_file
      @file || '(__TEMPLATE__)'
    end

    # An empty Hash that the template engine can populate with various
    # metadata.
    def metadata
      if respond_to?(:allows_script?)
        self.class.metadata.merge(:allows_script => allows_script?)
      else
        self.class.metadata
      end
    end

    # Set the prefix to use for compiled paths.
    def compiled_path=(path)
      if path
        # Use expanded paths when loading, since that is helpful
        # for coverage.  Remove any .rb suffix, since that will
        # be added back later.
        path = File.expand_path(path.sub(/\.rb\z/i, ''))
      end
      @compiled_path = path
    end

    # The compiled method for the locals keys and scope_class provided.
    # Returns an UnboundMethod, which can be used to define methods
    # directly on the scope class, which are much faster to call than
    # Tilt's normal rendering.
    def compiled_method(locals_keys, scope_class=nil)
      key = [scope_class, locals_keys].freeze
      LOCK.synchronize do
        if meth = @compiled_method[key]
          return meth
        end
      end
      meth = compile_template_method(locals_keys, scope_class)
      LOCK.synchronize do
        @compiled_method[key] = meth
      end
      meth
    end

    protected

    # @!group For template implementations

    # The encoding of the source data. Defaults to the
    # default_encoding-option if present. You may override this method
    # in your template class if you have a better hint of the data's
    # encoding.
    attr_reader :default_encoding

    def skip_compiled_encoding_detection?
      @skip_compiled_encoding_detection
    end

    # Do whatever preparation is necessary to setup the underlying template
    # engine. Called immediately after template data is loaded. Instance
    # variables set in this method are available when #evaluate is called.
    #
    # Empty by default as some subclasses do not need separate preparation.
    def prepare
    end

    CLASS_METHOD = Kernel.instance_method(:class)
    USE_BIND_CALL = RUBY_VERSION >= '2.7'

    # Execute the compiled template and return the result string. Template
    # evaluation is guaranteed to be performed in the scope object with the
    # locals specified and with support for yielding to the block.
    #
    # This method is only used by source generating templates. Subclasses that
    # override render() may not support all features.
    def evaluate(scope, locals, &block)
      locals_keys = locals.keys
      locals_keys.sort!{|x, y| x.to_s <=> y.to_s}

      case scope
      when Object
        scope_class = Module === scope ? scope : scope.class
      else
        # :nocov:
        scope_class = USE_BIND_CALL ? CLASS_METHOD.bind_call(scope) : CLASS_METHOD.bind(scope).call
        # :nocov:
      end
      method = compiled_method(locals_keys, scope_class)

      if USE_BIND_CALL
        method.bind_call(scope, locals, &block)
      # :nocov:
      else
        method.bind(scope).call(locals, &block)
      # :nocov:
      end
    end

    # Generates all template source by combining the preamble, template, and
    # postamble and returns a two-tuple of the form: [source, offset], where
    # source is the string containing (Ruby) source code for the template and
    # offset is the integer line offset where line reporting should begin.
    #
    # Template subclasses may override this method when they need complete
    # control over source generation or want to adjust the default line
    # offset. In most cases, overriding the #precompiled_template method is
    # easier and more appropriate.
    def precompiled(local_keys)
      preamble = precompiled_preamble(local_keys)
      template = precompiled_template(local_keys)
      postamble = precompiled_postamble(local_keys)
      source = String.new

      unless skip_compiled_encoding_detection?
        # Ensure that our generated source code has the same encoding as the
        # the source code generated by the template engine.
        template_encoding = extract_encoding(template){|t| template = t}

        if template.encoding != template_encoding
          # template should never be frozen here. If it was frozen originally,
          # then extract_encoding should yield a dup.
          template.force_encoding(template_encoding)
        end
      end

      source.force_encoding(template.encoding)
      source << preamble << "\n" << template << "\n" << postamble

      [source, preamble.count("\n")+1]
    end

    # A string containing the (Ruby) source code for the template. The
    # default Template#evaluate implementation requires either this
    # method or the #precompiled method be overridden. When defined,
    # the base Template guarantees correct file/line handling, locals
    # support, custom scopes, proper encoding, and support for template
    # compilation.
    def precompiled_template(local_keys)
      raise NotImplementedError
    end

    def precompiled_preamble(local_keys)
      ''
    end

    def precompiled_postamble(local_keys)
      ''
    end

    # !@endgroup

    private

    def process_arg(arg)
      if arg
        case
        when arg.respond_to?(:to_str)  ; @file = arg.to_str
        when arg.respond_to?(:to_int)  ; @line = arg.to_int
        when arg.respond_to?(:to_hash) ; @options = arg.to_hash.dup
        when arg.respond_to?(:path)    ; @file = arg.path
        when arg.respond_to?(:to_path) ; @file = arg.to_path
        else raise TypeError, "Can't load the template file. Pass a string with a path " +
          "or an object that responds to 'to_str', 'path' or 'to_path'"
        end
      end
    end

    def read_template_file
      data = File.binread(file)
      # Set it to the default external (without verifying)
      # :nocov:
      data.force_encoding(Encoding.default_external) if Encoding.default_external
      # :nocov:
      data
    end

    def set_compiled_method_cache
      @compiled_method = {}
    end

    def local_extraction(local_keys)
      assignments = local_keys.map do |k|
        if k.to_s =~ /\A[a-z_][a-zA-Z_0-9]*\z/
          "#{k} = locals[#{k.inspect}]"
        else
          raise "invalid locals key: #{k.inspect} (keys must be variable names)"
        end
      end

      s = "locals = locals[:locals]"
      if assignments.delete(s)
        # If there is a locals key itself named `locals`, delete it from the ordered keys so we can
        # assign it last. This is important because the assignment of all other locals depends on the
        # `locals` local variable still matching the `locals` method argument given to the method
        # created in `#compile_template_method`.
        assignments << s
      end

      assignments.join("\n")
    end

    def compile_template_method(local_keys, scope_class=nil)
      source, offset = precompiled(local_keys)
      local_code = local_extraction(local_keys)

      method_name = "__tilt_#{Thread.current.object_id.abs}"
      method_source = String.new
      method_source.force_encoding(source.encoding)

      if freeze_string_literals?
        method_source << "# frozen-string-literal: true\n"
      end

      # Don't indent method source, to avoid indentation warnings when using compiled paths
      method_source << "::Tilt::TOPOBJECT.class_eval do\ndef #{method_name}(locals)\n#{local_code}\n"

      offset += method_source.count("\n")
      method_source << source
      method_source << "\nend;end;"

      bind_compiled_method(method_source, offset, scope_class)
      unbind_compiled_method(method_name)
    end

    def bind_compiled_method(method_source, offset, scope_class)
      path = compiled_path
      if path && scope_class.name
        path = path.dup

        if defined?(@compiled_path_counter)
          path << '-' << @compiled_path_counter.succ!
        else
          @compiled_path_counter = "0".dup
        end
        path << ".rb"

        # Wrap method source in a class block for the scope, so constant lookup works
        if freeze_string_literals?
          method_source_prefix = "# frozen-string-literal: true\n"
          method_source = method_source.sub(/\A# frozen-string-literal: true\n/, '')
        end
        method_source = "#{method_source_prefix}class #{scope_class.name}\n#{method_source}\nend"

        load_compiled_method(path, method_source)
      else
        if path
          warn "compiled_path (#{compiled_path.inspect}) ignored on template with anonymous scope_class (#{scope_class.inspect})"
        end

        eval_compiled_method(method_source, offset, scope_class)
      end
    end

    def eval_compiled_method(method_source, offset, scope_class)
      (scope_class || Object).class_eval(method_source, eval_file, line - offset)
    end

    def load_compiled_method(path, method_source)
      File.binwrite(path, method_source)

      # Use load and not require, so unbind_compiled_method does not
      # break if the same path is used more than once.
      load path
    end

    def unbind_compiled_method(method_name)
      method = TOPOBJECT.instance_method(method_name)
      TOPOBJECT.class_eval { remove_method(method_name) }
      method
    end

    def extract_encoding(script, &block)
      extract_magic_comment(script, &block) || script.encoding
    end

    def extract_magic_comment(script)
      if script.frozen?
        script = script.dup
        yield script
      end

      binary(script) do
        script[/\A[ \t]*\#.*coding\s*[=:]\s*([[:alnum:]\-_]+).*$/n, 1]
      end
    end

    def freeze_string_literals?
      false
    end

    def binary(string)
      original_encoding = string.encoding
      string.force_encoding(Encoding::BINARY)
      yield
    ensure
      string.force_encoding(original_encoding)
    end
  end

  class StaticTemplate < Template
    def self.subclass(mime_type: 'text/html', &block)
      Class.new(self) do
        self.default_mime_type = mime_type

        private

        define_method(:_prepare_output, &block)
      end
    end

    # Static templates always return the prepared output.
    def render(scope=nil, locals=nil)
      @output
    end

    # Raise NotImplementedError, since static templates
    # do not support compiled methods.
    def compiled_method(locals_keys, scope_class=nil)
      raise NotImplementedError
    end

    # Static templates never allow script.
    def allows_script?
      false
    end

    protected

    def prepare
      @output = _prepare_output
    end

    private

    # Do nothing, since compiled method cache is not used.
    def set_compiled_method_cache
    end
  end
end
