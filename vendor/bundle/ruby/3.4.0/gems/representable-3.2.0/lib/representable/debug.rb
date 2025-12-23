require 'logger'

module Representable
  module Debug
    module_function def _representable_logger
      @logger ||= Logger.new(STDOUT)
    end

    module_function def representable_log(message)
      _representable_logger.debug { message }
    end

    def update_properties_from(doc, options, format)
      representable_log "[Deserialize]........."
      representable_log "[Deserialize] document #{doc.inspect}"
      super
    end

    def create_representation_with(doc, options, format)
      representable_log "[Serialize]........."
      representable_log "[Serialize]"
      super
    end

    def representable_map(*)
      super.tap do |arr|
        arr.collect { |bin| bin.extend(Binding) }
      end
    end

    module Binding
      def evaluate_option(name, *args, &block)
        Debug.representable_log "=====#{self[name]}" if name ==:prepare
        Debug.representable_log (evaled = self[name]) ?
          "                #evaluate_option [#{name}]: eval!!!" :
          "                #evaluate_option [#{name}]: skipping"
        value = super
        Debug.representable_log "                #evaluate_option [#{name}]: --> #{value}" if evaled
        Debug.representable_log "                #evaluate_option [#{name}]: -->= #{args.first}" if name == :setter
        value
      end

      def parse_pipeline(*)
        super.extend(Pipeline::Debug)
      end

      def render_pipeline(*)
        super.extend(Pipeline::Debug)
      end
    end
  end


  module Pipeline::Debug
    def call(input, options)
      Debug.representable_log "Pipeline#call: #{inspect}"
      Debug.representable_log "               input: #{input.inspect}"
      super
    end

    def evaluate(block, memo, options)
      block.extend(Pipeline::Debug) if block.is_a?(Collect)

      Debug.representable_log "  Pipeline   :   -> #{_inspect_function(block)} "
      super.tap do |res|
        Debug.representable_log "  Pipeline   :     result: #{res.inspect}"
      end
    end

    def inspect
      functions = collect do |func|
        _inspect_function(func)
      end.join(", ")
      "#{self.class.to_s.split("::").last}[#{functions}]"
    end

    # prints SkipParse instead of <Proc>. i know, i can make this better, but not now.
    def _inspect_function(func)
      return func.extend(Pipeline::Debug).inspect if func.is_a?(Collect)
      return func unless func.is_a?(Proc)

      File.readlines(func.source_location[0])[func.source_location[1]-1].match(/^\s+(\w+)/)[1]
    end
  end
end
