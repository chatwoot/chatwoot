# frozen_string_literal: true

module Aws
  module Endpoints
    # This class is deprecated. It is used by the Runtime endpoint
    # resolution approach. It has been replaced by a code generated
    # approach in each service gem. It can be removed in a new
    # major version. It has to exist because
    # old service gems can use a new core version.
    # @api private
    class Function
      def initialize(fn:, argv:)
        @fn = fn
        @argv = build_argv(argv)
      end

      attr_reader :fn
      attr_reader :argv

      def call(parameters, assigns)
        args = []
        @argv.each do |arg|
          if arg.is_a?(Reference)
            args << arg.resolve(parameters, assigns)
          elsif arg.is_a?(Function)
            args << arg.call(parameters, assigns)
          else
            if arg.is_a?(String)
              arg = Templater.resolve(arg, parameters, assigns)
            end
            args << arg
          end
        end

        case @fn
        when 'isSet'
          Matchers.set?(*args)
        when 'not'
          Matchers.not(*args)
        when 'getAttr'
          Matchers.attr(*args)
        when 'substring'
          Matchers.substring(*args)
        when 'stringEquals'
          Matchers.string_equals?(*args)
        when 'booleanEquals'
          Matchers.boolean_equals?(*args)
        when 'uriEncode'
          Matchers.uri_encode(*args)
        when 'parseURL'
          Matchers.parse_url(*args)
        when 'isValidHostLabel'
          Matchers.valid_host_label?(*args)
        when 'aws.partition'
          Matchers.aws_partition(*args)
        when 'aws.parseArn'
          Matchers.aws_parse_arn(*args)
        when 'aws.isVirtualHostableS3Bucket'
          Matchers.aws_virtual_hostable_s3_bucket?(*args)
        else
          raise "Function not found: #{@fn}"
        end
      end

      private

      def build_argv(argv_json)
        argv_json.each.with_object([]) do |arg, argv|
          argv << if arg.is_a?(Hash) && arg['ref']
                    Reference.new(ref: arg['ref'])
                  elsif arg.is_a?(Hash) && arg['fn']
                    Function.new(fn: arg['fn'], argv: arg['argv'])
                  else
                    arg
                  end
        end
      end
    end
  end
end
