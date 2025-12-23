# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Gapic
  module Rest
    ##
    # A class to provide the Enumerable interface to the response of a REST paginated method.
    # PagedEnumerable assumes response message holds a list of resources and the token to the next page.
    #
    # PagedEnumerable provides the enumerations over the resource data, and also provides the enumerations over the
    # pages themselves.
    #
    # @example normal iteration over resources.
    #   paged_enumerable.each { |resource| puts resource }
    #
    # @example per-page iteration.
    #   paged_enumerable.each_page { |page| puts page }
    #
    # @example Enumerable over pages.
    #   paged_enumerable.each_page do |page|
    #     page.each { |resource| puts resource }
    #   end
    #
    # @example more exact operations over pages.
    #   while some_condition()
    #     page = paged_enumerable.page
    #     do_something(page)
    #     break if paged_enumerable.next_page?
    #     paged_enumerable.next_page
    #   end
    #
    # @attribute [r] page
    #   @return [Page] The current page object.
    #
    class PagedEnumerable
      include Enumerable

      attr_reader :page

      ##
      # @private
      # @param service_stub [Object] The REST service_stub with the baseline implementation for the wrapped method.
      # @param method_name [Symbol] The REST method name that is being wrapped.
      # @param request [Object] The request object.
      # @param response [Object] The response object.
      # @param options [Gapic::CallOptions] The options for making the RPC call.
      # @param format_resource [Proc] A Proc object to format the resource object. The Proc should accept response as an
      #   argument, and return a formatted resource object. Optional.
      #
      def initialize service_stub, method_name, resource_field_name, request, response, options, format_resource: nil
        @service_stub = service_stub
        @method_name = method_name
        @resource_field_name = resource_field_name
        @request = request
        @response = response
        @options = options
        @format_resource = format_resource

        @page = Page.new response, resource_field_name, format_resource: @format_resource
      end

      ##
      # Iterate over the individual resources, automatically requesting new pages as needed.
      #
      # @yield [Object] Gives the resource objects in the stream.
      #
      # @return [Enumerator] if no block is provided
      #
      def each &block
        return enum_for :each unless block_given?

        each_page do |page|
          page.each(&block)
        end
      end

      ##
      # Iterate over the pages.
      #
      # @yield [Page] Gives the pages in the stream.
      #
      # @return [Enumerator] if no block is provided
      #
      def each_page
        return enum_for :each_page unless block_given?

        loop do
          break if @page.nil?
          yield @page
          next_page!
        end
      end

      ##
      # True if there is at least one more page of results.
      #
      # @return [Boolean]
      #
      def next_page?
        !next_page_token.nil? && !next_page_token.empty?
      end

      ##
      # Load the next page and set it as the current page.
      # If there is no next page, sets nil as a current page.
      #
      # @return [Page, nil] the new page object.
      #
      def next_page!
        unless next_page?
          @page = nil
          return @page
        end

        next_request = @request.dup
        next_request.page_token = @page.next_page_token

        @response = @service_stub.send @method_name, next_request, @options
        @page = Page.new @response, @resource_field_name, format_resource: @format_resource
      end
      alias next_page next_page!

      ##
      # The page token to be used for the next RPC call, or the empty string if there is no next page.
      # nil if the iteration is complete.
      #
      # @return [String, nil]
      #
      def next_page_token
        @page&.next_page_token
      end

      ##
      # The current response object, for the current page.
      # nil if the iteration is complete.
      #
      # @return [Object, nil]
      #
      def response
        @page&.response
      end

      ##
      # A class to represent a page in a PagedEnumerable. This also implements Enumerable, so it can iterate over the
      # resource elements.
      #
      # @attribute [r] response
      #   @return [Object] the response object for the page.
      class Page
        include Enumerable
        attr_reader :response

        ##
        # @private
        # @param response [Object] The response object for the page.
        # @param resource_field [String] The name of the field in response which holds the resources.
        # @param format_resource [Proc, nil] A Proc object to format the resource object. Default nil (no formatting).
        # The Proc should accept response as an argument, and return a formatted resource object. Optional.
        #
        def initialize response, resource_field, format_resource: nil
          @response = response
          @resource_field = resource_field
          @format_resource = format_resource
        end

        ##
        # Iterate over the resources.
        #
        # @yield [Object] Gives the resource objects in the page.
        #
        # @return [Enumerator] if no block is provided
        #
        def each
          return enum_for :each unless block_given?

          # We trust that the field exists and is an Enumerable
          resources.each do |resource|
            resource = @format_resource.call resource if @format_resource
            yield resource
          end
        end

        ##
        # The page token to be used for the next RPC call, or the empty string if there is no next page.
        #
        # @return [String]
        #
        def next_page_token
          @response.next_page_token
        end

        ##
        # Whether the next_page_token exists and is not empty
        #
        # @return [Boolean]
        #
        def next_page_token?
          !next_page_token.empty?
        end

        ##
        # Resources in this page presented as an array.
        # When the iterable is a protobuf map, the `.each |item|` gives just the keys
        # to iterate like a normal hash it should be converted to an array first
        #
        # @return [Array]
        #
        def resources
          @resources ||= @response[@resource_field].to_a
        end
      end
    end
  end
end
