# frozen_string_literal: true

require_relative "redactor"

module Datadog
  module DI
    # Serializes captured snapshot to primitive types, which are subsequently
    # serialized to JSON and sent to the backend.
    #
    # This class performs actual removal of sensitive values from the
    # snapshots. It uses Redactor to determine which values are sensitive
    # and need to be removed.
    #
    # Serializer normally ought not to invoke user (application) code,
    # to guarantee predictable performance. However, objects like ActiveRecord
    # models cannot be usefully serialized into primitive types without
    # custom logic (for example, the attributes are more than 3 levels
    # down from the top-level object which is the default capture depth,
    # thus they won't be captured at all). To accommodate complex objects,
    # there is an extension mechanism implemented permitting registration
    # of serializer callbacks for arbitrary types. Applications and libraries
    # definining such serializer callbacks should be very careful to
    # have predictable performance and avoid exceptions and infinite loops
    # and other such issues.
    #
    # All serialization methods take the names of the variables being
    # serialized in order to be able to redact values.
    #
    # The result of serialization should not reference parameter values when
    # the values are mutable (currently, this only applies to string values).
    # Serializer will duplicate such mutable values, so that if method
    # arguments are captured at entry and then modified during method execution,
    # the serialized values from entry are correctly preserved.
    # Alternatively, we could pass a parameter to the serialization methods
    # which would control whether values are duplicated. This may be more
    # efficient but there would be additional overhead from passing this
    # parameter all the time and the API would get more complex.
    #
    # Note: "self" cannot be used as a parameter name in Ruby, therefore
    # there should never be a conflict between instance variable
    # serialization and method parameters.
    #
    # @api private
    class Serializer
      # Third-party library integration / custom serializers.
      #
      # Dynamic instrumentation has limited payload sizes, and for efficiency
      # reasons it is not desirable to transmit data to Datadog that will
      # never contain useful information. Additionally, due to depth limits,
      # desired data may not even be included in payloads when serialized
      # with the default, naive serializer. Therefore, custom objects like
      # ActiveRecord model instances may need custom serializers.
      #
      # CUSTOMER NOTE: The API for defining custom serializers is not yet
      # finalized. Please create an issue at
      # https://github.com/datadog/dd-trace-rb/issues describing the
      # object(s) you wish to serialize so that we can ensure your use case
      # will be supported as the library evolves.
      #
      # Note that the current implementation does not permit defining a
      # serializer for a particular class, which is the simplest use case.
      # This is because the library itself does not need this functionality
      # yet, and it won't help for ActiveRecord models (that derive from
      # a common base class but are all of different classes) or for Mongoid
      # models (that do not have a common base class at all but include a
      # standard Mongoid module).
      @@flat_registry = []
      def self.register(condition: nil, &block)
        @@flat_registry << {condition: condition, proc: block}
      end

      def initialize(settings, redactor, telemetry: nil)
        @settings = settings
        @redactor = redactor
        @telemetry = telemetry
      end

      attr_reader :settings
      attr_reader :redactor
      attr_reader :telemetry

      # Serializes positional and keyword arguments to a method,
      # as obtained by a method probe.
      #
      # UI supports a single argument list only and does not distinguish
      # between positional and keyword arguments. We convert positional
      # arguments to keyword arguments ("arg1", "arg2", ...) and ensure
      # the positional arguments are listed first.
      #
      # Instance variables are technically a hash just like kwargs,
      # we take them as a separate parameter to avoid a hash merge
      # in upstream code.
      def serialize_args(args, kwargs, target_self,
        depth: settings.dynamic_instrumentation.max_capture_depth,
        attribute_count: settings.dynamic_instrumentation.max_capture_attribute_count)
        counter = 0
        combined = args.each_with_object({}) do |value, c|
          counter += 1
          # Conversion to symbol is needed here to put args ahead of
          # kwargs when they are merged below.
          c[:"arg#{counter}"] = value
        end.update(kwargs).update(self: target_self)
        serialize_vars(combined, depth: depth, attribute_count: attribute_count)
      end

      # Serializes variables captured by a line probe.
      #
      # These are normally local variables that exist on a particular line
      # of executed code.
      def serialize_vars(vars,
        depth: settings.dynamic_instrumentation.max_capture_depth,
        attribute_count: settings.dynamic_instrumentation.max_capture_attribute_count)
        vars.each_with_object({}) do |(k, v), agg|
          agg[k] = serialize_value(v, name: k, depth: depth, attribute_count: attribute_count)
        end
      end

      # Serializes a single named value.
      #
      # The name is needed to perform sensitive data redaction.
      #
      # In some cases, the value being serialized does not have a name
      # (for example, it is the return value of a method).
      # In this case +name+ can be nil.
      #
      # Returns a data structure comprised of only values of basic types
      # (integers, strings, arrays, hashes).
      #
      # Respects string length, collection size and traversal depth limits.
      def serialize_value(value, name: nil,
        depth: settings.dynamic_instrumentation.max_capture_depth,
        attribute_count: nil,
        type: nil)
        attribute_count ||= settings.dynamic_instrumentation.max_capture_attribute_count
        cls = type || value.class
        begin
          if redactor.redact_type?(value)
            return {type: class_name(cls), notCapturedReason: "redactedType"}
          end

          if name && redactor.redact_identifier?(name)
            return {type: class_name(cls), notCapturedReason: "redactedIdent"}
          end

          @@flat_registry.each do |entry|
            if (condition = entry[:condition]) && condition.call(value)
              serializer_proc = entry.fetch(:proc)
              return serializer_proc.call(self, value, name: nil, depth: depth)
            end
          end

          serialized = {type: class_name(cls)}
          case value
          when NilClass
            serialized.update(isNull: true)
          when Integer, Float, TrueClass, FalseClass
            serialized.update(value: value.to_s)
          when Time
            # This path also handles DateTime values although they do not need
            # to be explicitly added to the case statement.
            serialized.update(value: value.iso8601)
          when Date
            serialized.update(value: value.to_s)
          when String, Symbol
            need_dup = false
            value = if String === value
              # This is the only place where we duplicate the value, currently.
              # All other values are immutable primitives (e.g. numbers).
              # However, do not duplicate if the string is frozen, or if
              # it is later truncated.
              need_dup = !value.frozen?
              value
            else
              value.to_s
            end
            max = settings.dynamic_instrumentation.max_capture_string_length
            if value.length > max
              serialized.update(truncated: true, size: value.length)
              value = value[0...max]
              need_dup = false
            end
            value = value.dup if need_dup
            serialized.update(value: value)
          when Array
            if depth < 0
              serialized.update(notCapturedReason: "depth")
            else
              max = settings.dynamic_instrumentation.max_capture_collection_size
              if max != 0 && value.length > max
                serialized.update(notCapturedReason: "collectionSize", size: value.length)
                # same steep failure with array slices.
                # https://github.com/soutaro/steep/issues/1219
                value = value[0...max] || []
              end
              entries = value.map do |elt|
                serialize_value(elt, depth: depth - 1)
              end
              serialized.update(elements: entries)
            end
          when Hash
            if depth < 0
              serialized.update(notCapturedReason: "depth")
            else
              max = settings.dynamic_instrumentation.max_capture_collection_size
              cur = 0
              entries = []
              value.each do |k, v|
                if max != 0 && cur >= max
                  serialized.update(notCapturedReason: "collectionSize", size: value.length)
                  break
                end
                cur += 1
                entries << [serialize_value(k, depth: depth - 1), serialize_value(v, name: k, depth: depth - 1)]
              end
              serialized.update(entries: entries)
            end
          else
            if depth < 0
              serialized.update(notCapturedReason: "depth")
            else
              fields = {}
              cur = 0

              # MRI and JRuby 9.4.5+ preserve instance variable definition
              # order when calling #instance_variables. Previous JRuby versions
              # did not preserve order and returned the variables in arbitrary
              # order.
              #
              # The arbitrary order is problematic because 1) when there are
              # fewer instance variables than capture limit, the order in which
              # the variables are shown in UI will change from one capture to
              # the next and generally will be arbitrary to the user, and
              # 2) when there are more instance variables than capture limit,
              # *which* variables are captured will also change meaning user
              # looking at the UI may have "new" instance variables appear and
              # existing ones disappear as they are looking at multiple captures.
              #
              # For consistency, we should have some kind of stable order of
              # instance variables on all supported Ruby runtimes, so that the UI
              # stays consistent. Given that initial implementation of Ruby DI
              # does not support JRuby, we don't handle JRuby's lack of ordering
              # of #instance_variables here, but if JRuby is supported in the
              # future this may need to be addressed.
              ivars = value.instance_variables

              ivars.each do |ivar|
                if cur >= attribute_count
                  serialized.update(notCapturedReason: "fieldCount", fields: fields)
                  break
                end
                cur += 1
                fields[ivar] = serialize_value(value.instance_variable_get(ivar), name: ivar, depth: depth - 1)
              end
              serialized.update(fields: fields)
            end
          end
          serialized
        rescue => exc
          telemetry&.report(exc, description: "Error serializing")
          {type: class_name(cls), notSerializedReason: exc.to_s}
        end
      end

      private

      # Returns the name for the specified class object.
      #
      # Ruby can have nameless classes, e.g. Class.new is a class object
      # with no name. We return a placeholder for such nameless classes.
      def class_name(cls)
        # We could call `cls.to_s` to get the "standard" Ruby inspection of
        # the class, but it is likely that user code can override #to_s
        # and we don't want to invoke user code.
        cls.name || "[Unnamed class]"
      end
    end
  end
end
