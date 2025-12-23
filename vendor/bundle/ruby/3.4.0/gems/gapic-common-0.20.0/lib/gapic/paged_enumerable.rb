# Copyright 2019 Google LLC
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
  ##
  # A class to provide the Enumerable interface to the response of a paginated method. PagedEnumerable assumes
  # response message holds a list of resources and the token to the next page.
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
  class PagedEnumerable
    include Enumerable

    ##
    # @attribute [r] page
    #   @return [Page] The current page object.
    attr_reader :page

    ##
    # @private
    # @param grpc_stub [Gapic::GRPC::Stub] The Gapic gRPC stub object.
    # @param method_name [Symbol] The RPC method name.
    # @param request [Object] The request object.
    # @param response [Object] The response object.
    # @param operation [::GRPC::ActiveCall::Operation] The RPC operation for the response.
    # @param options [Gapic::CallOptions] The options for making the RPC call.
    # @param format_resource [Proc] A Proc object to format the resource object. The Proc should accept response as an
    #   argument, and return a formatted resource object. Optional.
    #
    def initialize grpc_stub, method_name, request, response, operation, options, format_resource: nil
      @grpc_stub = grpc_stub
      @method_name = method_name
      @request = request
      @response = response
      @options = options
      @format_resource = format_resource
      @resource_field = nil # will be set in verify_response!

      verify_request!
      verify_response!

      @page = Page.new @response, @resource_field, operation, format_resource: @format_resource
    end

    ##
    # Iterate over the resources.
    #
    # @yield [Object] Gives the resource objects in the stream.
    #
    # @raise [RuntimeError] if it's not started yet.
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
    # @raise if it's not started yet.
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
    # True if it has the next page.
    #
    def next_page?
      @page.next_page_token?
    end

    ##
    # Update the response in the current page.
    #
    # @return [Page] the new page object.
    #
    def next_page!
      unless next_page?
        @page = nil
        return @page
      end

      next_request = @request.dup
      next_request.page_token = @page.next_page_token
      @grpc_stub.call_rpc @method_name, next_request, options: @options do |next_response, next_operation|
        @page = Page.new next_response, @resource_field, next_operation, format_resource: @format_resource
      end
      @page
    end
    alias next_page next_page!

    ##
    # The page token to be used for the next RPC call.
    #
    # @return [String]
    #
    def next_page_token
      @page.next_page_token
    end

    ##
    # The current response object, for the current page.
    #
    # @return [Object]
    #
    def response
      @page.response
    end

    private

    def verify_request!
      page_token = @request.class.descriptor.find do |f|
        f.name == "page_token" && f.type == :string
      end
      raise ArgumentError, "#{@request.class} must have a page_token field (String)" if page_token.nil?

      page_size = @request.class.descriptor.find do |f|
        f.name == "page_size" && [:int32, :int64].include?(f.type)
      end
      return unless page_size.nil?
      raise ArgumentError, "#{@request.class} must have a page_size field (Integer)"
    end

    def verify_response!
      next_page_token = @response.class.descriptor.find do |f|
        f.name == "next_page_token" && f.type == :string
      end
      raise ArgumentError, "#{@response.class} must have a next_page_token field (String)" if next_page_token.nil?

      # Find all repeated FieldDescriptors on the response Descriptor
      fields = @response.class.descriptor.select do |f|
        f.label == :repeated && f.type == :message
      end

      repeated_field = fields.first
      raise ArgumentError, "#{@response.class} must have one repeated field" if repeated_field.nil?

      min_repeated_field_number = fields.map(&:number).min
      if min_repeated_field_number != repeated_field.number
        raise ArgumentError, "#{@response.class} must have one primary repeated field by both position and number"
      end

      # We have the correct repeated field, save the field's name
      @resource_field = repeated_field.name
    end

    ##
    # A class to represent a page in a PagedEnumerable. This also implements Enumerable, so it can iterate over the
    # resource elements.
    #
    # @attribute [r] response
    #   @return [Object] the response object for the page.
    # @attribute [r] operation
    #   @return [::GRPC::ActiveCall::Operation] the RPC operation for the page.
    class Page
      include Enumerable
      attr_reader :response
      attr_reader :operation

      ##
      # @private
      # @param response [Object] The response object for the page.
      # @param resource_field [String] The name of the field in response which holds the resources.
      # @param operation [::GRPC::ActiveCall::Operation] the RPC operation for the page.
      # @param format_resource [Proc] A Proc object to format the resource object. The Proc should accept response as an
      #   argument, and return a formatted resource object. Optional.
      #
      def initialize response, resource_field, operation, format_resource: nil
        @response = response
        @resource_field = resource_field
        @operation = operation
        @format_resource = format_resource
      end

      ##
      # Iterate over the resources.
      #
      # @yield [Object] Gives the resource objects in the page.
      #
      def each
        return enum_for :each unless block_given?

        return if @response.nil?

        # We trust that the field exists and is an Enumerable
        @response[@resource_field].each do |resource|
          resource = @format_resource.call resource if @format_resource
          yield resource
        end
      end

      ##
      # The page token to be used for the next RPC call.
      #
      # @return [String]
      #
      def next_page_token
        return if @response.nil?

        @response.next_page_token
      end

      ##
      # Truthiness of next_page_token.
      #
      # @return [Boolean]
      #
      def next_page_token?
        return if @response.nil?

        !@response.next_page_token.empty?
      end
    end
  end
end
