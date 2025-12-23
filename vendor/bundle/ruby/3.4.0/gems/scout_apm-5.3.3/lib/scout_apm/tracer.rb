# Provides helpers to wrap sections of code in instrumentation
#
# The manual approach is to wrap your code in a call like:
#     `instrument("View", "users/index") do ... end`
#
# The monkey-patching approach does this for you:
#     `instrument_method(:my_render, :type => "View", :name => "users/index)`

module ScoutApm
  module Tracer
    def self.included(klass)
      klass.extend ClassMethods
    end

    # Type: the Layer type - "View" or similar
    # Name: specific name - "users/_gravatar". The object must respond to "#to_s". This allows us to be more efficient - in most cases, the metric name isn't needed unless we are processing a slow transaction.
    # A Block: The code to be instrumented
    #
    # Options:
    # * :ignore_children - will not instrument any method calls beneath this call. Example use case: InfluxDB uses Net::HTTP, which is instrumented. However, we can provide more specific data if we know we're doing an influx call, so we'd rather just instrument the Influx call and ignore Net::HTTP.
    #   when rendering the transaction tree in the UI.
    # * :desc - Additional capture, SQL, or HTTP url or similar
    # * :scope - set to true if you want to make this layer a subscope
    def self.instrument(type, name, options={}) # Takes a block
      layer = ScoutApm::Layer.new(type, name)
      layer.desc = options[:desc] if options[:desc]
      layer.subscopable!          if options[:scope]

      req = ScoutApm::RequestManager.lookup
      req.start_layer(layer)
      req.ignore_children! if options[:ignore_children]

      begin
        yield
      ensure
        req.acknowledge_children! if options[:ignore_children]
        req.stop_layer
      end
    end

    module ClassMethods
      # See ScoutApm::Tracer.instrument
      def instrument(type, name, options={}, &block)
        ScoutApm::Tracer.instrument(type, name, options, &block)
      end

      # Wraps a method in a call to #instrument via aggressive monkey patching.
      #
      # Options:
      # type - "View" or "ActiveRecord" and similar
      # name - "users/show", "App#find"
      def instrument_method(method_name, options = {})
        ScoutApm::Agent.instance.context.logger.info "Instrumenting #{method_name}"
        type = options[:type] || "Custom"
        name = options[:name] || "#{self.name}/#{method_name.to_s}"

        instrumented_name, uninstrumented_name = _determine_instrumented_name(method_name, type)

        ScoutApm::Agent.instance.context.logger.info "Instrumenting #{instrumented_name}, #{uninstrumented_name}"

        return if !_instrumentable?(method_name) or _instrumented?(instrumented_name, method_name)

        class_eval(
          _instrumented_method_string(instrumented_name, uninstrumented_name, type, name, {:scope => options[:scope] }),
          __FILE__, __LINE__
        )

        alias_method uninstrumented_name, method_name
        alias_method method_name, instrumented_name
      end

      private

      def _determine_instrumented_name(method_name, type)
        inst = _find_unused_method_name { _instrumented_method_name(method_name, type) }
        uninst = _find_unused_method_name { _uninstrumented_method_name(method_name, type) }

        return inst, uninst
      end

      def _find_unused_method_name
        raw_name = name = yield

        i = 0
        while method_defined?(name) && i < 100
          i += 1
          name = "#{raw_name}_#{i}"
        end
        name
      end

      def _instrumented_method_string(instrumented_name, uninstrumented_name, type, name, options={})
        method_str = <<-EOF
        def #{instrumented_name}(*args#{", **kwargs" if ScoutApm::Agent.instance.context.environment.supports_kwarg_delegation?}, &block)
          name = begin
                   "#{name}"
                 rescue => e
                   ScoutApm::Agent.instance.context.logger.error("Error raised while interpreting instrumented name: %s, %s" % ['#{name}', e.message])
                   "Unknown"
                 end

          ::ScoutApm::Tracer.instrument( "#{type}",
                               name,
                               {:scope => #{options[:scope] || false}}
                             ) do
            #{uninstrumented_name}(*args#{", **kwargs" if ScoutApm::Agent.instance.context.environment.supports_kwarg_delegation?}, &block)
          end
        end
        EOF

        method_str
      end

      # The method must exist to be instrumented.
      def _instrumentable?(method_name)
        exists = method_defined?(method_name) || private_method_defined?(method_name)
        ScoutApm::Agent.instance.context.logger.warn "The method [#{self.name}##{method_name}] does not exist and will not be instrumented" unless exists
        exists
      end

      # +True+ if the method is already instrumented.
      def _instrumented?(instrumented_name, method_name)
        instrumented = method_defined?(instrumented_name)
        ScoutApm::Agent.instance.context.logger.warn("The method [#{self.name}##{method_name}] has already been instrumented") if instrumented
        instrumented
      end

      # given a method and a metric, this method returns the
      # untraced alias of the method name
      def _uninstrumented_method_name(method_name, type)
        "#{_sanitize_name(method_name)}_without_scout_instrument"
      end

      # given a method and a metric, this method returns the traced
      # alias of the method name
      def _instrumented_method_name(method_name, type)
        "#{_sanitize_name(method_name)}_with_scout_instrument"
      end

      # Method names like +any?+ or +replace!+ contain a trailing character that would break when
      # eval'd as ? and ! aren't allowed inside method names.
      def _sanitize_name(name)
        name.to_s.tr_s('^a-zA-Z0-9', '_')
      end
    end
  end
end
