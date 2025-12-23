# frozen_string_literal: true

module Aws
  # @api private
  class ParamValidator

    include Seahorse::Model::Shapes

    EXPECTED_GOT = 'expected %s to be %s, got class %s instead.'

    # @param [Seahorse::Model::Shapes::ShapeRef] rules
    # @param [Hash] params
    # @return [void]
    def self.validate!(rules, params)
      new(rules).validate!(params)
    end

    # @param [Seahorse::Model::Shapes::ShapeRef] rules
    # @option options [Boolean] :validate_required (true)
    def initialize(rules, options = {})
      @rules = rules || begin
        shape = StructureShape.new
        shape.struct_class = EmptyStructure
        ShapeRef.new(shape: shape)
      end
      @validate_required = options[:validate_required] != false
      @input = options[:input].nil? ? true : !!options[:input]
    end

    # @param [Hash] params
    # @return [void]
    def validate!(params)
      errors = []
      structure(@rules, params, errors, 'params') if @rules
      raise ArgumentError, error_messages(errors) unless errors.empty?
    end

    private

    def structure(ref, values, errors, context)
      # ensure the value is hash like
      return unless correct_type?(ref, values, errors, context)

      if ref.eventstream
        # input eventstream is provided from event signals
        values.each do |value|
          # each event is structure type
          case value[:message_type]
          when 'event'
            val = value.dup
            val.delete(:message_type)
            structure(ref.shape.member(val[:event_type]), val, errors, context)
          when 'error' # Error is unmodeled
          when 'exception' # Pending
            raise Aws::Errors::EventStreamParserError.new(
              ':exception event validation is not supported')
          end
        end
      else
        shape = ref.shape

        # ensure required members are present
        if @validate_required
          shape.required.each do |member_name|
            input_eventstream = ref.shape.member(member_name).eventstream && @input
            if values[member_name].nil? && !input_eventstream
              param = "#{context}[#{member_name.inspect}]"
              errors << "missing required parameter #{param}"
            end
          end
        end

        if @validate_required && shape.union
          if values.length > 1
            errors << "multiple values provided to union at #{context} - must contain exactly one of the supported types: #{shape.member_names.join(', ')}"
          elsif values.length == 0
            errors << "No values provided to union at #{context} - must contain exactly one of the supported types: #{shape.member_names.join(', ')}"
          end
        end

        # validate non-nil members
        values.each_pair do |name, value|
          unless value.nil?
            # :event_type is not modeled
            # and also needed when construct body
            next if name == :event_type
            if shape.member?(name)
              member_ref = shape.member(name)
              shape(member_ref, value, errors, context + "[#{name.inspect}]")
            else
              errors << "unexpected value at #{context}[#{name.inspect}]"
            end
          end
        end

      end
    end

    def list(ref, values, errors, context)
      # ensure the value is an array
      unless values.is_a?(Array)
        errors << expected_got(context, "an Array", values)
        return
      end

      # validate members
      member_ref = ref.shape.member
      values.each.with_index do |value, index|
        shape(member_ref, value, errors, context + "[#{index}]")
      end
    end

    def map(ref, values, errors, context)
      unless Hash === values
        errors << expected_got(context, "a hash", values)
        return
      end

      key_ref = ref.shape.key
      value_ref = ref.shape.value

      values.each do |key, value|
        shape(key_ref, key, errors, "#{context} #{key.inspect} key")
        shape(value_ref, value, errors, context + "[#{key.inspect}]")
      end
    end

    def document(ref, value, errors, context)
      document_types = [Hash, Array, Numeric, String, TrueClass, FalseClass, NilClass]
      unless document_types.any? { |t| value.is_a?(t) }
        errors << expected_got(context, "one of #{document_types.join(', ')}", value)
      end

      # recursively validate types for aggregated types
      case value
      when Hash
        value.each do |k, v|
          document(ref, v, errors, context + "[#{k}]")
        end
      when Array
        value.each do |v|
          document(ref, v, errors, context)
        end
      end

    end

    def shape(ref, value, errors, context)
      case ref.shape
      when StructureShape then structure(ref, value, errors, context)
      when ListShape then list(ref, value, errors, context)
      when MapShape then map(ref, value, errors, context)
      when DocumentShape then document(ref, value, errors, context)
      when StringShape
        unless value.is_a?(String)
          errors << expected_got(context, "a String", value)
        end
      when IntegerShape
        unless value.is_a?(Integer)
          errors << expected_got(context, "an Integer", value)
        end
      when FloatShape
        unless value.is_a?(Float)
          errors << expected_got(context, "a Float", value)
        end
      when TimestampShape
        unless value.is_a?(Time)
          errors << expected_got(context, "a Time object", value)
        end
      when BooleanShape
        unless [true, false].include?(value)
          errors << expected_got(context, "true or false", value)
        end
      when BlobShape
        unless value.is_a?(String)
          if streaming_input?(ref)
            unless io_like?(value, _require_size = false)
              errors << expected_got(
                context,
                "a String or IO like object that supports read and rewind",
                value
              )
            end
          elsif !io_like?(value, _require_size = true)
            errors << expected_got(
              context,
              "a String or IO like object that supports read, rewind, and size",
              value
            )
          end
        end
      else
        raise "unhandled shape type: #{ref.shape.class.name}"
      end
    end

    def correct_type?(ref, value, errors, context)
      if ref.eventstream && @input
        errors << "instead of providing value directly for eventstreams at input,"\
                  " expected to use #signal events per stream"
        return false
      end
      case value
      when Hash then true
      when ref.shape.struct_class then true
      when Enumerator then ref.eventstream && value.respond_to?(:event_types)
      else
        errors << expected_got(context, "a hash", value)
        false
      end
    end

    def io_like?(value, require_size = true)
      value.respond_to?(:read) && value.respond_to?(:rewind) &&
        (!require_size || value.respond_to?(:size))
    end

    def streaming_input?(ref)
      (ref["streaming"] || ref.shape["streaming"])
    end

    def error_messages(errors)
      if errors.size == 1
        errors.first
      else
        prefix = "\n  - "
        "parameter validator found #{errors.size} errors:" +
          prefix + errors.join(prefix)
      end
    end

    def expected_got(context, expected, got)
      EXPECTED_GOT % [context, expected, got.class.name]
    end

  end
end
