# frozen_string_literal: true

require 'cgi'

module Aws
  module Endpoints
    # generic matcher functions for service endpoints
    # @api private
    module Matchers
      # Regex that extracts anything in square brackets
      BRACKET_REGEX = /\[(.*?)\]/.freeze

      # CORE

      # isSet(value: Option<T>) bool
      def self.set?(value)
        !value.nil?
      end

      # not(value: bool) bool
      def self.not(bool)
        !bool
      end

      # getAttr(value: Object | Array, path: string) Document
      def self.attr(value, path)
        parts = path.split('.')

        val = if (index = parts.first[BRACKET_REGEX, 1])
                # remove brackets and index from part before indexing
                value[parts.first.gsub(BRACKET_REGEX, '')][index.to_i]
              else
                value[parts.first]
              end

        if parts.size == 1
          val
        else
          attr(val, parts.slice(1..-1).join('.'))
        end
      end

      def self.substring(input, start, stop, reverse)
        return nil if start >= stop || input.size < stop

        return nil if input.chars.any? { |c| c.ord > 127 }

        return input[start...stop] unless reverse

        r_start = input.size - stop
        r_stop = input.size - start
        input[r_start...r_stop]
      end

      # stringEquals(value1: string, value2: string) bool
      def self.string_equals?(value1, value2)
        value1 == value2
      end

      # booleanEquals(value1: bool, value2: bool) bool
      def self.boolean_equals?(value1, value2)
        value1 == value2
      end

      # uriEncode(value: string) string
      def self.uri_encode(value)
        CGI.escape(value.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
      end

      # parseUrl(value: string) Option<URL>
      def self.parse_url(value)
        URL.new(value).as_json
      rescue ArgumentError, URI::InvalidURIError
        nil
      end

      # isValidHostLabel(value: string, allowSubDomains: bool) bool
      def self.valid_host_label?(value, allow_sub_domains = false)
        return false if value.empty?

        if allow_sub_domains
          labels = value.split('.', -1)
          return labels.all? { |l| valid_host_label?(l) }
        end

        !!(value =~ /\A(?!-)[a-zA-Z0-9-]{1,63}(?<!-)\z/)
      end

      # AWS

      # aws.partition(value: string) Option<Partition>
      def self.aws_partition(value)
        partition =
          Aws::Partitions.find { |p| p.region?(value) } ||
          Aws::Partitions.find { |p| value.match(p.region_regex) } ||
          Aws::Partitions.find { |p| p.name == 'aws' }

        return nil unless partition

        partition.metadata
      end

      # aws.parseArn(value: string) Option<ARN>
      def self.aws_parse_arn(value)
        arn = Aws::ARNParser.parse(value)
        json = arn.as_json
        # HACK: because of poor naming and also requirement of splitting
        resource = json.delete('resource')
        json['resourceId'] = resource.split(%r{[:\/]}, -1)
        json
      rescue Aws::Errors::InvalidARNError
        nil
      end

      # aws.isVirtualHostableS3Bucket(value: string, allowSubDomains: bool) bool
      def self.aws_virtual_hostable_s3_bucket?(value, allow_sub_domains = false)
        return false if value.empty?

        if allow_sub_domains
          labels = value.split('.', -1)
          return labels.all? { |l| aws_virtual_hostable_s3_bucket?(l) }
        end

        # must be between 3 and 63 characters long, no uppercase
        value =~ /\A(?!-)[a-z0-9-]{3,63}(?<!-)\z/ &&
          # not an IP address
          value !~ /(\d+\.){3}\d+/
      end
    end
  end
end
