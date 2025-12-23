# frozen_string_literal: true

module Stripe
  class ListObject < StripeObject
    include Enumerable
    include Stripe::APIOperations::List
    include Stripe::APIOperations::Request
    include Stripe::APIOperations::Create

    OBJECT_NAME = "list"
    def self.object_name
      "list"
    end

    # This accessor allows a `ListObject` to inherit various filters that were
    # given to a predecessor. This allows for things like consistent limits,
    # expansions, and predicates as a user pages through resources.
    attr_accessor :filters

    # An empty list object. This is returned from +next+ when we know that
    # there isn't a next page in order to replicate the behavior of the API
    # when it attempts to return a page beyond the last.
    def self.empty_list(opts = {})
      ListObject.construct_from({ data: [] }, opts, nil, :v1)
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
              "You tried to access the #{key.inspect} index, but ListObject " \
              "types only support String keys. (HINT: List calls return an " \
              "object with a 'data' (which is the data array). You likely " \
              "want to call #data[#{key.inspect}])"
      end
    end

    # Iterates through each resource in the page represented by the current
    # `ListObject`.
    #
    # Note that this method makes no effort to fetch a new page when it gets to
    # the end of the current page's resources. See also +auto_paging_each+.
    def each(&blk)
      data.each(&blk)
    end

    # Iterates through each resource in all pages, making additional fetches to
    # the API as necessary.
    #
    # The default iteration direction is forwards according to Stripe's API
    # "natural" ordering direction -- newer objects first, and moving towards
    # older objects.
    #
    # However, if the initial list object was fetched using an `ending_before`
    # cursor (and only `ending_before`, `starting_after` cannot also be
    # included), the method assumes that the user is trying to iterate
    # backwards compared to natural ordering and returns results that way --
    # older objects first, and moving towards newer objects.
    #
    # Note that this method will make as many API calls as necessary to fetch
    # all resources. For more granular control, please see +each+ and
    # +next_page+.
    def auto_paging_each(&blk)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      loop do
        # Backward iterating activates if we have an `ending_before` constraint
        # and _just_ an `ending_before` constraint. If `starting_after` was
        # also used, we iterate forwards normally.
        if filters.include?(:ending_before) &&
           !filters.include?(:starting_after)
          page.reverse_each(&blk)
          page = page.previous_page
        else
          page.each(&blk)
          page = page.next_page
        end

        break if page.empty?
      end
    end

    # Returns true if the page object contains no elements.
    def empty?
      data.empty?
    end

    def retrieve(id, opts = {})
      id, retrieve_params = Util.normalize_id(id)
      url = "#{resource_url}/#{CGI.escape(id)}"
      execute_resource_request(:get, url, :api, retrieve_params, opts)
    end

    # Fetches the next page in the resource list (if there is one).
    #
    # This method will try to respect the limit of the current page. If none
    # was given, the default limit will be fetched again.
    def next_page(params = {}, opts = {})
      return self.class.empty_list(opts) unless has_more

      last_id = data.last.id

      params = filters.merge(starting_after: last_id).merge(params)

      list(params, opts)
    end

    # Fetches the previous page in the resource list (if there is one).
    #
    # This method will try to respect the limit of the current page. If none
    # was given, the default limit will be fetched again.
    def previous_page(params = {}, opts = {})
      return self.class.empty_list(opts) unless has_more

      first_id = data.first.id

      params = filters.merge(ending_before: first_id).merge(params)

      list(params, opts)
    end

    def resource_url
      url ||
        raise(ArgumentError, "List object does not contain a 'url' field.")
    end

    # Iterates through each resource in the page represented by the current
    # `ListObject` in reverse.
    def reverse_each(&blk)
      data.reverse_each(&blk)
    end
  end
end
