# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module OpenSearch
  module API
    # Generic utility methods
    #
    module Utils
      # URL-escape a string
      #
      # @example
      #     __escape('foo/bar') # => 'foo%2Fbar'
      #     __escape('bar^bam') # => 'bar%5Ebam'
      #
      # @api private
      def __escape(string)
        return string if string == '*'

        CGI.escape(string.to_s)
      end

      # Create a "list" of values from arguments, ignoring nil values and encoding special characters.
      #
      # @example Create a list from array
      #     __listify(['A','B']) # => 'A,B'
      #
      # @example Create a list from arguments
      #     __listify('A','B') # => 'A,B'
      #
      # @example Escape values
      #     __listify('foo','bar^bam') # => 'foo,bar%5Ebam'
      #
      # @example Do not escape the values
      #     __listify('foo','bar^bam', escape: false) # => 'foo,bar^bam'
      #
      # @api private
      def __listify(*list)
        options = list.last.is_a?(Hash) ? list.pop : {}

        escape = options[:escape]
        Array(list)
          .flat_map { |e| e.respond_to?(:split) ? e.split(',') : e }
          .flatten
          .compact
          .map { |e| escape == false ? e : __escape(e) }
          .join(',')
      end

      # Create a path (URL part) from arguments, ignoring nil values and empty strings.
      #
      # @example Create a path from array
      #     __pathify(['foo', '', nil, 'bar']) # => 'foo/bar'
      #
      # @example Create a path from arguments
      #     __pathify('foo', '', nil, 'bar') # => 'foo/bar'
      #
      # # @example Encode special characters
      #     __pathify(['foo', 'bar^bam']) # => 'foo/bar%5Ebam'
      #
      # @api private
      def __pathify(*segments)
        Array(segments).flatten
                       .compact
                       .reject { |s| s.to_s.strip.empty? }
                       .join('/')
                       .squeeze('/')
      end

      # Convert an array of payloads into OpenSearch `header\ndata` format
      #
      # Supports various different formats of the payload: Array of Strings, Header/Data pairs,
      # or the conveniency "combined" format where data is passed along with the header
      # in a single item.
      #
      #     OpenSearch::API::Utils.__bulkify [
      #       { :index =>  { :_index => 'myindexA', :_id => '1', :data => { :title => 'Test' } } },
      #       { :update => { :_index => 'myindexB', :_id => '2', :data => { :doc => { :title => 'Update' } } } }
      #     ]
      #
      #     # => {"index":{"_index":"myindexA","_id":"1"}}
      #     # => {"title":"Test"}
      #     # => {"update":{"_index":"myindexB","_id":"2"}}
      #     # => {"doc":{"title":"Update"}}
      #
      def __bulkify(payload)
        operations = %w[index create delete update]

        # Hashes with `:data`
        if payload.any? do |d|
             d.is_a?(Hash) && d.values.first.is_a?(Hash) && operations.include?(d.keys.first.to_s) && (d.values.first[:data] || d.values.first['data'])
           end
          payload = payload
                    .each_with_object([]) do |item, sum|
                      operation, meta = item.to_a.first
                      meta            = meta.clone
                      data            = meta.delete(:data) || meta.delete('data')

                      sum << { operation => meta }
                      sum << data if data
                    end
          payload = payload.map { |item| OpenSearch::API.serializer.dump(item) }
          payload << '' unless payload.empty?

        # Array of strings
        elsif payload.all? { |d| d.is_a? String }
          payload << ''

        # Header/Data pairs
        else
          payload = payload.map { |item| OpenSearch::API.serializer.dump(item) }
          payload << ''
        end

        payload = payload.join("\n")
      end

      # Validates the argument Hash against common and valid API parameters
      #
      # @param arguments    [Hash]          Hash of arguments to verify and extract, **with symbolized keys**
      # @param valid_params [Array<Symbol>] An array of symbols with valid keys
      #
      # @return [Hash]         Return whitelisted Hash
      # @raise [ArgumentError] If the arguments Hash contains invalid keys
      #
      # @example Extract parameters
      #   __validate_and_extract_params( { :foo => 'qux' }, [:foo, :bar] )
      #   # => { :foo => 'qux' }
      #
      # @example Raise an exception for invalid parameters
      #   __validate_and_extract_params( { :foo => 'qux', :bam => 'mux' }, [:foo, :bar] )
      #   # ArgumentError: "URL parameter 'bam' is not supported"
      #
      # @example Skip validating parameters
      #   __validate_and_extract_params( { :foo => 'q', :bam => 'm' }, [:foo, :bar], { skip_parameter_validation: true } )
      #   # => { :foo => "q", :bam => "m" }
      #
      # @example Skip validating parameters when the module setting is set
      #   OpenSearch::API.settings[:skip_parameter_validation] = true
      #   __validate_and_extract_params( { :foo => 'q', :bam => 'm' }, [:foo, :bar] )
      #   # => { :foo => "q", :bam => "m" }
      #
      # @api private
      #
      def __validate_and_extract_params(arguments, params = [], options = {})
        if options[:skip_parameter_validation] || OpenSearch::API.settings[:skip_parameter_validation]
          arguments
        else
          __validate_params(arguments, params)
          __extract_params(arguments, params, options.merge(escape: false))
        end
      end

      def __validate_params(arguments, valid_params = [])
        arguments.each do |k, _v|
          raise ArgumentError, "URL parameter '#{k}' is not supported" \
            unless COMMON_PARAMS.include?(k) || COMMON_QUERY_PARAMS.include?(k) || valid_params.include?(k)
        end
      end

      def __extract_params(arguments, params = [], options = {})
        result = arguments.select { |k, _v| COMMON_QUERY_PARAMS.include?(k) || params.include?(k) }
        result = result.to_h unless result.is_a?(Hash) # Normalize Ruby 1.8 and Ruby 1.9 Hash#select behaviour
        result.map { |k, v| v.is_a?(Array) ? [k, __listify(v, options)] : [k, v] }.to_h # Listify Arrays
      end

      # Extracts the valid parts of the URL from the arguments
      #
      # @note Mutates the `arguments` argument, to prevent failures in `__validate_and_extract_params`.
      #
      # @param arguments   [Hash]          Hash of arguments to verify and extract, **with symbolized keys**
      # @param valid_parts [Array<Symbol>] An array of symbol with valid keys
      #
      # @return [Array<String>]            Valid parts of the URL as an array of strings
      #
      # @example Extract parts
      #   __extract_parts { :foo => true }, [:foo, :bar]
      #   # => [:foo]
      #
      #
      # @api private
      #
      def __extract_parts(arguments, valid_parts = [])
        parts = arguments.select { |k, _v| valid_parts.include?(k) }.to_h
        parts = parts.reduce([]) do |sum, item|
          k, v = item
          sum << (v.is_a?(TrueClass) ? k.to_s : v)
        end

        arguments.delete_if { |k, _v| valid_parts.include? k }
        parts
      end

      # Calls the given block, rescuing from `StandardError`.
      #
      # Primary use case is the `:ignore` parameter for API calls.
      #
      # Returns `false` if exception contains NotFound in its class name or message,
      # else re-raises the exception.
      #
      # @yield [block] A block of code to be executed with exception handling.
      #
      # @api private
      #
      def __rescue_from_not_found
        yield
      rescue StandardError => e
        raise e unless e.class.to_s =~ /NotFound/ || e.message =~ /Not\s*Found/i
        false
      end

      def __report_unsupported_parameters(arguments, params = [])
        messages = []
        unsupported_params = params.select do |d|
          d.is_a?(Hash) ? arguments.include?(d.keys.first) : arguments.include?(d)
        end

        unsupported_params.each do |param|
          name = case param
                 when Symbol
                   param
                 when Hash
                   param.keys.first
                 else
                   raise ArgumentError, 'The param must be a Symbol or a Hash'
                 end

          explanation = if param.is_a?(Hash)
                          ". #{param.values.first[:explanation]}."
                        else
                          ". This parameter is not supported in the version you're using: #{OpenSearch::VERSION}, and will be removed in the next release."
                        end

          message = "[!] You are using unsupported parameter [:#{name}]"

          if (source = caller&.last)
            message += " in `#{source}`"
          end

          message += explanation

          messages << message
        end

        return if messages.empty?

        messages << 'Suppress this warning by the `-WO` command line flag.'

        if $stderr.tty?
          Kernel.warn messages.map { |m| "\e[31;1m#{m}\e[0m" }.join("\n")
        else
          Kernel.warn messages.join("\n")
        end
      end

      def __report_unsupported_method(name)
        message = "[!] You are using unsupported method [#{name}]"
        if (source = caller&.last)
          message += " in `#{source}`"
        end

        message += ". This method is not supported in the version you're using: #{OpenSearch::VERSION}, and will be removed in the next release. Suppress this warning by the `-WO` command line flag."

        if $stderr.tty?
          Kernel.warn "\e[31;1m#{message}\e[0m"
        else
          Kernel.warn message
        end
      end

      extend self
    end
  end
end
