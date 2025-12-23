# frozen_string_literal: true

module Stripe
  module V2
    class ListObject < StripeObject
      OBJECT_NAME = "list"
      def self.object_name
        "list"
      end

      # An empty list object. This is returned from +fetch_next_page+ when we know that
      # there isn't a next page.
      def self.empty_list(opts = {})
        ListObject.construct_from({ data: [] }, opts, nil, :v2)
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

      # Iterates through each resource in the page represented by the current
      # `ListObject` in reverse.
      def reverse_each(&blk)
        data.reverse_each(&blk)
      end

      # Iterates through each resource in all pages, making additional fetches to
      # the API as necessary.
      #
      # Note that this method will make as many API calls as necessary to fetch
      # all resources. For more granular control, please see +each+ and
      # +fetch_next_page+.
      def auto_paging_each(&blk)
        return enum_for(:auto_paging_each) unless block_given?

        page = self
        loop do
          page.each(&blk)

          break if page.next_page_url.nil?

          page = page.fetch_next_page
        end
      end

      # Returns true if the page object contains no elements.
      def empty?
        data.empty?
      end

      # Fetches the next page in the resource list (if there is one).
      #
      # This method will try to respect the limit of the current page. If none
      # was given, the default limit will be fetched again.
      def fetch_next_page(opts = {})
        return self.class.empty_list(opts) if next_page_url.nil?

        _request(
          method: :get,
          path: next_page_url,
          base_address: :api
        )
      end
    end
  end
end
