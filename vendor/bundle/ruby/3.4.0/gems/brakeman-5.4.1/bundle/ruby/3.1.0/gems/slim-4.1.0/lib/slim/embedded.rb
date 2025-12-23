module Slim
  # @api private
  class TextCollector < Filter
    def call(exp)
      @collected = ''
      super(exp)
      @collected
    end

    def on_slim_interpolate(text)
      @collected << text
      nil
    end
  end

  # @api private
  class NewlineCollector < Filter
    def call(exp)
      @collected = [:multi]
      super(exp)
      @collected
    end

    def on_newline
      @collected << [:newline]
      nil
    end
  end

  # @api private
  class OutputProtector < Filter
    def call(exp)
      @protect, @collected, @tag = [], '', "%#{object_id.abs.to_s(36)}%"
      super(exp)
      @collected
    end

    def on_static(text)
      @collected << text
      nil
    end

    def on_slim_output(escape, text, content)
      @collected << @tag
      @protect << [:slim, :output, escape, text, content]
      nil
    end

    def unprotect(text)
      block = [:multi]
      while text =~ /#{@tag}/
        block << [:static, $`]
        block << @protect.shift
        text = $'
      end
      block << [:static, text]
    end
  end

  # Temple filter which processes embedded engines
  # @api private
  class Embedded < Filter
    @engines = {}

    class << self
      attr_reader :engines

      # Register embedded engine
      #
      # @param [String] name Name of the engine
      # @param [Class]  klass Engine class
      # @param option_filter List of options to pass to engine.
      #                      Last argument can be default option hash.
      def register(name, klass, *option_filter)
        name = name.to_sym
        local_options = option_filter.last.respond_to?(:to_hash) ? option_filter.pop.to_hash : {}
        define_options(name, *option_filter)
        klass.define_options(name)
        engines[name.to_sym] = proc do |options|
          klass.new({}.update(options).delete_if {|k,v| !option_filter.include?(k) && k != name }.update(local_options))
        end
      end

      def create(name, options)
        constructor = engines[name] || raise(Temple::FilterError, "Embedded engine #{name} not found")
        constructor.call(options)
      end
    end

    define_options :enable_engines, :disable_engines

    def initialize(opts = {})
      super
      @engines = {}
      @enabled = normalize_engine_list(options[:enable_engines])
      @disabled = normalize_engine_list(options[:disable_engines])
    end

    def on_slim_embedded(name, body, attrs)
      name = name.to_sym
      raise(Temple::FilterError, "Embedded engine #{name} is disabled") unless enabled?(name)
      @engines[name] ||= self.class.create(name, options)
      @engines[name].on_slim_embedded(name, body, attrs)
    end

    def enabled?(name)
      (!@enabled || @enabled.include?(name)) &&
        (!@disabled || !@disabled.include?(name))
    end

    protected

    def normalize_engine_list(list)
      raise(ArgumentError, "Option :enable_engines/:disable_engines must be String or Symbol list") unless !list || Array === list
      list && list.map(&:to_sym)
    end

    class Engine < Filter
      protected

      def collect_text(body)
        @text_collector ||= TextCollector.new
        @text_collector.call(body)
      end

      def collect_newlines(body)
        @newline_collector ||= NewlineCollector.new
        @newline_collector.call(body)
      end
    end

    # Basic tilt engine
    class TiltEngine < Engine
      def on_slim_embedded(engine, body, attrs)
        tilt_engine = Tilt[engine] || raise(Temple::FilterError, "Tilt engine #{engine} is not available.")
        tilt_options = options[engine.to_sym] || {}
        tilt_options[:default_encoding] ||= 'utf-8'
        [:multi, tilt_render(tilt_engine, tilt_options, collect_text(body)), collect_newlines(body)]
      end

      protected

      def tilt_render(tilt_engine, tilt_options, text)
        [:static, tilt_engine.new(tilt_options) { text }.render]
      end
    end

    # Sass engine which supports :pretty option
    class SassEngine < TiltEngine
      define_options :pretty

      protected

      def tilt_render(tilt_engine, tilt_options, text)
        text = tilt_engine.new(tilt_options.merge(
          style: options[:pretty] ? :expanded : :compressed,
          cache: false)) { text }.render
        text.chomp!
        [:static, text]
      end
    end

    # Static template with interpolated ruby code
    class InterpolateTiltEngine < TiltEngine
      def collect_text(body)
        output_protector.call(interpolation.call(body))
      end

      def tilt_render(tilt_engine, tilt_options, text)
        output_protector.unprotect(tilt_engine.new(tilt_options) { text }.render)
      end

      private

      def interpolation
        @interpolation ||= Interpolation.new
      end

      def output_protector
        @output_protector ||= OutputProtector.new
      end
    end

    # Tag wrapper engine
    # Generates a html tag and wraps another engine (specified via :engine option)
    class TagEngine < Engine
      disable_option_validator!

      def on_slim_embedded(engine, body, attrs)

        unless options[:attributes].empty?
          options[:attributes].map do|k, v|
            attrs << [:html, :attr, k, [:static, v]]
          end
        end

        if options[:engine]
          opts = {}.update(options)
          opts.delete(:engine)
          opts.delete(:tag)
          opts.delete(:attributes)
          @engine ||= options[:engine].new(opts)
          body = @engine.on_slim_embedded(engine, body, attrs)
        end

        [:html, :tag, options[:tag], attrs, body]
      end

    end

    # Javascript wrapper engine.
    # Like TagEngine, but can wrap content in html comment or cdata.
    class JavaScriptEngine < TagEngine
      disable_option_validator!

      set_options tag: :script, attributes: {}

      def on_slim_embedded(engine, body, attrs)
        super(engine, [:html, :js, body], attrs)
      end
    end

    # Embeds ruby code
    class RubyEngine < Engine
      def on_slim_embedded(engine, body, attrs)
        [:multi, [:newline], [:code, "#{collect_text(body)}\n"]]
      end
    end

    # These engines are executed at compile time, embedded ruby is interpolated
    register :markdown,   InterpolateTiltEngine
    register :textile,    InterpolateTiltEngine
    register :rdoc,       InterpolateTiltEngine

    # These engines are executed at compile time
    register :coffee,     JavaScriptEngine, engine: TiltEngine
    register :less,       TagEngine, tag: :style,  attributes: { type: 'text/css' },         engine: TiltEngine
    register :sass,       TagEngine, :pretty, tag: :style, attributes: { type: 'text/css' }, engine: SassEngine
    register :scss,       TagEngine, :pretty, tag: :style, attributes: { type: 'text/css' }, engine: SassEngine

    # Embedded javascript/css
    register :javascript, JavaScriptEngine
    register :css,        TagEngine, tag: :style,  attributes: { type: 'text/css' }

    # Embedded ruby code
    register :ruby,       RubyEngine
  end
end
