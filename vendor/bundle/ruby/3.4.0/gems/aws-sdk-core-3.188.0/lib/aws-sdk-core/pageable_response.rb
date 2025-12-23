# frozen_string_literal: true

module Aws
  # Decorates a {Seahorse::Client::Response} with paging convenience methods.
  # Some AWS calls provide paged responses to limit the amount of data returned
  # with each response. To optimize for latency, some APIs may return an
  # inconsistent number of responses per page. You should rely on the values of
  # the `next_page?` method or using enumerable methods such as `each` rather
  # than the number of items returned to iterate through results. See below for
  # examples.
  #
  # @note Methods such as `to_json` will enumerate all of the responses before
  #   returning the full response as JSON.
  #
  # # Paged Responses Are Enumerable
  # The simplest way to handle paged response data is to use the built-in
  # enumerator in the response object, as shown in the following example.
  #
  #     s3 = Aws::S3::Client.new
  #
  #     s3.list_objects(bucket:'aws-sdk').each do |response|
  #       puts response.contents.map(&:key)
  #     end
  #
  # This yields one response object per API call made, and enumerates objects
  # in the named bucket. The SDK retrieves additional pages of data to
  # complete the request.
  #
  # # Handling Paged Responses Manually
  # To handle paging yourself, use the response’s `next_page?` method to verify
  # there are more pages to retrieve, or use the last_page? method to verify
  # there are no more pages to retrieve.
  #
  # If there are more pages, use the `next_page` method to retrieve the
  # next page of results, as shown in the following example.
  #
  #     s3 = Aws::S3::Client.new
  #
  #     # Get the first page of data
  #     response = s3.list_objects(bucket:'aws-sdk')
  #
  #     # Get additional pages
  #     while response.next_page? do
  #       response = response.next_page
  #       # Use the response data here...
  #       puts response.contents.map(&:key)
  #     end
  #
  module PageableResponse

    def self.apply(base)
      base.extend Extension
      base.instance_variable_set(:@last_page, nil)
      base.instance_variable_set(:@more_results, nil)
      base
    end

    # @return [Paging::Pager]
    attr_accessor :pager

    # Returns `true` if there are no more results.  Calling {#next_page}
    # when this method returns `false` will raise an error.
    # @return [Boolean]
    def last_page?
      # Actual implementation is in PageableResponse::Extension
    end

    # Returns `true` if there are more results.  Calling {#next_page} will
    # return the next response.
    # @return [Boolean]
    def next_page?
      # Actual implementation is in PageableResponse::Extension
    end

    # @return [Seahorse::Client::Response]
    def next_page(params = {})
      # Actual implementation is in PageableResponse::Extension
    end

    # Yields the current and each following response to the given block.
    # @yieldparam [Response] response
    # @return [Enumerable,nil] Returns a new Enumerable if no block is given.
    def each(&block)
      # Actual implementation is in PageableResponse::Extension
    end
    alias each_page each

    private

    # @param [Hash] params A hash of additional request params to
    #   merge into the next page request.
    # @return [Seahorse::Client::Response] Returns the next page of
    #   results.
    def next_response(params)
      # Actual implementation is in PageableResponse::Extension
    end

    # @param [Hash] params A hash of additional request params to
    #   merge into the next page request.
    # @return [Hash] Returns the hash of request parameters for the
    #   next page, merging any given params.
    def next_page_params(params)
      # Actual implementation is in PageableResponse::Extension
    end

    # Raised when calling {PageableResponse#next_page} on a pager that
    # is on the last page of results.  You can call {PageableResponse#last_page?}
    # or {PageableResponse#next_page?} to know if there are more pages.
    class LastPageError < RuntimeError

      # @param [Seahorse::Client::Response] response
      def initialize(response)
        @response = response
        super("unable to fetch next page, end of results reached")
      end

      # @return [Seahorse::Client::Response]
      attr_reader :response

    end

    # A handful of Enumerable methods, such as #count are not safe
    # to call on a pageable response, as this would trigger n api calls
    # simply to count the number of response pages, when likely what is
    # wanted is to access count on the data. Same for #to_h.
    # @api private
    module UnsafeEnumerableMethods

      def count
        if data.respond_to?(:count)
          data.count
        else
          raise NoMethodError, "undefined method `count'"
        end
      end

      def respond_to?(method_name, *args)
        if method_name == :count
          data.respond_to?(:count)
        else
          super
        end
      end

      def to_h
        data.to_h
      end

      def as_json(_options = {})
        data.to_h(data, as_json: true)
      end

      def to_json(options = {})
        as_json.to_json(options)
      end
    end

    # The actual decorator module implementation. It is in a distinct module
    # so that it can be used to extend objects without busting Ruby's constant cache.
    # object.extend(mod) bust the constant cache only if `mod` contains constants of its own.
    # @api private
    module Extension

      include Enumerable
      include UnsafeEnumerableMethods

      attr_accessor :pager

      def last_page?
        if @last_page.nil?
          @last_page = !@pager.truncated?(self)
        end
        @last_page
      end

      def next_page?
        !last_page?
      end

      def next_page(params = {})
        if last_page?
          raise LastPageError.new(self)
        else
          next_response(params)
        end
      end

      def each(&block)
        return enum_for(:each_page) unless block_given?
        response = self
        yield(response)
        until response.last_page?
          response = response.next_page
          yield(response)
        end
      end
      alias each_page each

      private

      def next_response(params)
        params = next_page_params(params)
        request = context.client.build_request(context.operation_name, params)
        Aws::Plugins::UserAgent.feature('paginator') do
          request.send_request
        end
      end

      def next_page_params(params)
        # Remove all previous tokens from original params
        # Sometimes a token can be nil and merge would not include it.
        tokens = @pager.tokens.values.map(&:to_sym)

        params_without_tokens = context[:original_params].reject { |k, _v| tokens.include?(k) }
        params_without_tokens.merge!(@pager.next_tokens(self).merge(params))
        params_without_tokens
      end

    end
  end
end
