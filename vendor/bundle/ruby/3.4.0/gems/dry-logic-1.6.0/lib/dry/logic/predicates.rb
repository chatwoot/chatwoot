# frozen_string_literal: true

require "dry/core/constants"

require "bigdecimal"
require "bigdecimal/util"
require "date"
require "uri"

module Dry
  module Logic
    module Predicates
      include ::Dry::Core::Constants

      # rubocop:disable Metrics/ModuleLength
      module Methods
        def self.uuid_format(version)
          ::Regexp.new(<<~FORMAT.chomp, ::Regexp::IGNORECASE)
            \\A[0-9A-F]{8}-[0-9A-F]{4}-#{version}[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\\z
          FORMAT
        end

        UUIDv1 = uuid_format(1)

        UUIDv2 = uuid_format(2)

        UUIDv3 = uuid_format(3)

        UUIDv4 = uuid_format(4)

        UUIDv5 = uuid_format(5)

        UUIDv6 = uuid_format(6)

        UUIDv7 = uuid_format(7)

        UUIDv8 = uuid_format(8)

        def [](name)
          method(name)
        end

        def type?(type, input) = input.is_a?(type)

        def nil?(input) = input.nil?
        alias_method :none?, :nil?

        def key?(name, input) = input.key?(name)

        def attr?(name, input) = input.respond_to?(name)

        def empty?(input)
          case input
          when ::String, ::Array, ::Hash then input.empty?
          when nil then true
          else
            false
          end
        end

        def filled?(input) = !empty?(input)

        def bool?(input) = input.equal?(true) || input.equal?(false)

        def date?(input) = input.is_a?(::Date)

        def date_time?(input) = input.is_a?(::DateTime)

        def time?(input) = input.is_a?(::Time)

        def number?(input)
          true if Float(input)
        rescue ::ArgumentError, ::TypeError
          false
        end

        def int?(input) = input.is_a?(::Integer)

        def float?(input) = input.is_a?(::Float)

        def decimal?(input) = input.is_a?(::BigDecimal)

        def str?(input) = input.is_a?(::String)

        def hash?(input) = input.is_a?(::Hash)

        def array?(input) = input.is_a?(::Array)

        def odd?(input) = input.odd?

        def even?(input) = input.even?

        def lt?(num, input) = input < num

        def gt?(num, input) = input > num

        def lteq?(num, input) = !gt?(num, input)

        def gteq?(num, input) = !lt?(num, input)

        def size?(size, input)
          case size
          when ::Integer then size.equal?(input.size)
          when ::Range, ::Array then size.include?(input.size)
          else
            raise ::ArgumentError, "+#{size}+ is not supported type for size? predicate."
          end
        end

        def min_size?(num, input) = input.size >= num

        def max_size?(num, input) = input.size <= num

        def bytesize?(size, input)
          case size
          when ::Integer then size.equal?(input.bytesize)
          when ::Range, ::Array then size.include?(input.bytesize)
          else
            raise ::ArgumentError, "+#{size}+ is not supported type for bytesize? predicate."
          end
        end

        def min_bytesize?(num, input) = input.bytesize >= num

        def max_bytesize?(num, input) = input.bytesize <= num

        def inclusion?(list, input)
          deprecated(:inclusion?, :included_in?)
          included_in?(list, input)
        end

        def exclusion?(list, input)
          deprecated(:exclusion?, :excluded_from?)
          excluded_from?(list, input)
        end

        def included_in?(list, input) = list.include?(input)

        def excluded_from?(list, input) = !list.include?(input)

        def includes?(value, input)
          if input.respond_to?(:include?)
            input.include?(value)
          else
            false
          end
        rescue ::TypeError
          false
        end

        def excludes?(value, input) = !includes?(value, input)

        # This overrides Object#eql? so we need to make it compatible
        def eql?(left, right = Undefined)
          return super(left) if right.equal?(Undefined)

          left.eql?(right)
        end

        def is?(left, right) = left.equal?(right)

        def not_eql?(left, right) = !left.eql?(right)

        def true?(value) = value.equal?(true)

        def false?(value) = value.equal?(false)

        def format?(regex, input) = !input.nil? && regex.match?(input)

        def case?(pattern, input) = pattern === input # rubocop:disable Style/CaseEquality

        def uuid_v1?(input) = format?(UUIDv1, input)

        def uuid_v2?(input) = format?(UUIDv2, input)

        def uuid_v3?(input) = format?(UUIDv3, input)

        def uuid_v4?(input) = format?(UUIDv4, input)

        def uuid_v5?(input) = format?(UUIDv5, input)

        def uuid_v6?(input) = format?(UUIDv6, input)

        def uuid_v7?(input) = format?(UUIDv7, input)

        def uuid_v8?(input) = format?(UUIDv8, input)

        if defined?(::URI::RFC2396_PARSER)
          def uri?(schemes, input)
            uri_format = ::URI::RFC2396_PARSER.make_regexp(schemes)
            format?(uri_format, input)
          end
        else
          def uri?(schemes, input)
            uri_format = ::URI::DEFAULT_PARSER.make_regexp(schemes)
            format?(uri_format, input)
          end
        end

        def uri_rfc3986?(input) = format?(::URI::RFC3986_Parser::RFC3986_URI, input)

        # This overrides Object#respond_to? so we need to make it compatible
        def respond_to?(method, input = Undefined)
          return super if input.equal?(Undefined)

          input.respond_to?(method)
        end

        def predicate(name, &)
          define_singleton_method(name, &)
        end

        def deprecated(name, in_favor_of)
          Core::Deprecations.warn(
            "#{name} predicate is deprecated and will " \
            "be removed in the next major version\n" \
            "Please use #{in_favor_of} predicate instead",
            tag: "dry-logic",
            uplevel: 3
          )
        end
      end

      extend Methods

      def self.included(other)
        super
        other.extend(Methods)
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
