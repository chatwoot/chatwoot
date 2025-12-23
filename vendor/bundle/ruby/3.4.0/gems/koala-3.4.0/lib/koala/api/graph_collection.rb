require 'addressable/uri'

module Koala
  module Facebook
    class API
      # A light wrapper for collections returned from the Graph API.
      # It extends Array to allow you to page backward and forward through
      # result sets, and providing easy access to paging information.
      class GraphCollection < Array

        # The raw paging information from Facebook (next/previous URLs).
        attr_reader :paging
        # The raw summary information from Facebook (total counts).
        attr_reader :summary
        # @return [Koala::Facebook::GraphAPI] the api used to make requests.
        attr_reader :api
        # The entire raw response from Facebook.
        attr_reader :raw_response
        # The headers from the Facebook response
        attr_reader :headers

        # Initialize the array of results and store various additional paging-related information.
        #
        # @param [Koala::HTTPService::Response] response object wrapping the raw Facebook response
        # @param api the Graph {Koala::Facebook::API API} instance to use to make calls
        #            (usually the API that made the original call).
        #
        # @return [Koala::Facebook::API::GraphCollection] an initialized GraphCollection
        #         whose paging, summary, raw_response, and api attributes are populated.
        def initialize(response, api)
          super response.data["data"]
          @paging = response.data["paging"]
          @summary = response.data["summary"]
          @raw_response = response.data
          @api = api
          @headers = response.headers
        end

        # @private
        # Turn the response into a GraphCollection if they're pageable;
        # if not, return the data of the original response.
        # The Ads API (uniquely so far) returns a hash rather than an array when queried
        # with get_connections.
        def self.evaluate(response, api)
          return nil if response.nil?

          is_pageable?(response) ? self.new(response, api) : response.data
        end

        # response will always be an instance of Koala::HTTPService::Response
        # since that is what we get from Koala::Facebook::API#api
        def self.is_pageable?(response)
          response.data.is_a?(Hash) && response.data["data"].is_a?(Array)
        end

        # Retrieve the next page of results.
        #
        # @param [Hash] extra_params Some optional extra parameters for paging. For supported parameters see https://developers.facebook.com/docs/reference/api/pagination/
        #
        # @example With optional extra params
        #    wall = api.get_connections("me", "feed", since: 1379593891)
        #    wall.next_page(since: 1379593891)
        #
        # @return a GraphCollection array of additional results (an empty array if there are no more results)
        def next_page(extra_params = {})
          base, args = next_page_params
          base ? @api.get_page([base, args.merge(extra_params)]) : nil
        end

        # Retrieve the previous page of results.
        #
        # @param [Hash] extra_params Some optional extra parameters for paging. For supported parameters see https://developers.facebook.com/docs/reference/api/pagination/
        #
        # @return a GraphCollection array of additional results (an empty array if there are no earlier results)
        def previous_page(extra_params = {})
          base, args = previous_page_params
          base ? @api.get_page([base, args.merge(extra_params)]) : nil
        end

        # Arguments that can be sent to {Koala::Facebook::API#graph_call} to retrieve the next page of results.
        #
        # @example
        #           @api.graph_call(*collection.next_page_params)
        #
        # @return an array of arguments, or nil if there are no more pages
        def next_page_params
          @paging && @paging["next"] ? parse_page_url(@paging["next"]) : nil
        end

        # Arguments that can be sent to {Koala::Facebook::API#graph_call} to retrieve the previous page of results.
        #
        # @example
        #           @api.graph_call(*collection.previous_page_params)
        #
        # @return an array of arguments, or nil if there are no previous pages
        def previous_page_params
          @paging && @paging["previous"] ? parse_page_url(@paging["previous"]) : nil
        end

        # @private
        def parse_page_url(url)
          GraphCollection.parse_page_url(url)
        end

        # Parse the previous and next page URLs Facebook provides in pageable results.
        # You'll mainly need to use this when using a non-Rails framework (one without url_for);
        # to store paging information between page loads, pass the URL (from GraphCollection#paging)
        # and use parse_page_url to turn it into parameters useful for {Koala::Facebook::API#get_page}.
        #
        # @param url the paging URL to turn into graph_call parameters
        #
        # @return an array of parameters that can be provided via graph_call(*parsed_params)
        def self.parse_page_url(url)
          uri = Addressable::URI.parse(url)

          base = uri.path.sub(/^\//, '')
          params = CGI.parse(uri.query)

          new_params = {}
          params.each_pair do |key,value|
            new_params[key] = value.join ","
          end
          [base,new_params]
        end
      end
    end
  end
end
