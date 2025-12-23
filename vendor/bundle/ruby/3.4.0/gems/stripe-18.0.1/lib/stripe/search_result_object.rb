# frozen_string_literal: true

module Stripe
  class SearchResultObject < StripeObject
    include Enumerable
    include Stripe::APIOperations::Search
    include Stripe::APIOperations::Request

    OBJECT_NAME = "search_result"
    def self.object_name
      "search_result"
    end

    # This accessor allows a `SearchResultObject` to inherit various filters
    # that were given to a predecessor. This allows for things like consistent
    # limits, expansions, and predicates as a user pages through resources.
    attr_accessor :filters

    # An empty search result object. This is returned from +next+ when we know
    # that there isn't a next page in order to replicate the behavior of the API
    # when it attempts to return a page beyond the last.
    def self.empty_search_result(opts = {})
      SearchResultObject.construct_from({ data: [] }, opts, :v1)
    end

    def initialize(*args)
      super
      self.filters = {}
    end

    def [](key)
      case key
      when String, Symbol
        super
      else
        raise ArgumentError,
              "You tried to access the #{key.inspect} index, but " \
              "SearchResultObject types only support String keys. " \
              "(HINT: Search calls return an object with a 'data' (which is " \
              "the data array). You likely want to call #data[#{key.inspect}])"
      end
    end

    # Iterates through each resource in the page represented by the current
    # `SearchListObject`.
    #
    # Note that this method makes no effort to fetch a new page when it gets to
    # the end of the current page's resources. See also +auto_paging_each+.
    def each(&blk)
      data.each(&blk)
    end

    # Returns true if the page object contains no elements.
    def empty?
      data.empty?
    end

    # Iterates through each resource in all pages, making additional fetches to
    # the API as necessary.
    #
    # Note that this method will make as many API calls as necessary to fetch
    # all resources. For more granular control, please see +each+ and
    # +next_search_result_page+.
    def auto_paging_each(&blk)
      return enum_for(:auto_paging_each) unless block_given?

      page = self

      loop do
        page.each(&blk)
        page = page.next_search_result_page

        break if page.empty?
      end
    end

    # Fetches the next page in the resource list (if there is one).
    #
    # This method will try to respect the limit of the current page. If none
    # was given, the default limit will be fetched again.
    def next_search_result_page(params = {}, opts = {})
      return self.class.empty_search_result(opts) unless has_more

      params = filters.merge(page: next_page).merge(params)

      request_stripe_object(method: :get, path: url, params: params, opts: opts)
    end
  end
end
