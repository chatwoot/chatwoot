# frozen_string_literal: true

module Twilio
  module REST
    # Page Base Class
    class Page
      include Enumerable

      META_KEYS = [
        'end',
        'first_page_uri',
        'next_page_uri',
        'last_page_uri',
        'page',
        'page_size',
        'previous_page_uri',
        'total',
        'num_pages',
        'start',
        'uri'
      ].freeze

      def initialize(version, response)
        payload = process_response(response)

        @version = version
        @payload = payload
        @solution = {}
        @records = load_page(payload)
      end

      def process_response(response)
        if response.status_code != 200
          raise Twilio::REST::RestError.new('Unable to fetch page', response)
        end

        response.body
      end

      def load_page(payload)
        return payload['Resources'] if payload['Resources']
        if payload['meta'] && payload['meta']['key']
          return payload[payload['meta']['key']]
        else
          keys = payload.keys
          key = keys - META_KEYS
          return payload[key.first] if key.size == 1
        end

        raise Twilio::REST::TwilioError, 'Page Records can not be deserialized'
      end

      def previous_page_url
        if @payload['meta'] && @payload['meta']['previous_page_url']
          return @version.domain.absolute_url(URI.parse(@payload['meta']['previous_page_url']).request_uri)
        elsif @payload['previous_page_uri']
          return @version.domain.absolute_url(@payload['previous_page_uri'])
        end

        nil
      end

      def next_page_url
        if @payload['meta'] && @payload['meta']['next_page_url']
          return @version.domain.absolute_url(URI.parse(@payload['meta']['next_page_url']).request_uri)
        elsif @payload['next_page_uri']
          return @version.domain.absolute_url(@payload['next_page_uri'])
        end

        nil
      end

      def get_instance(payload)
        raise Twilio::REST::TwilioError, 'Page.get_instance() must be implemented in the derived class'
      end

      def previous_page
        return nil unless previous_page_url

        response = @version.domain.request('GET', previous_page_url)

        self.class.new(@version, response, @solution)
      end

      def next_page
        return nil unless next_page_url

        response = @version.domain.request('GET', next_page_url)

        self.class.new(@version, response, @solution)
      end

      def each
        @records.each do |record|
          yield get_instance(record)
        end
      end

      def to_s
        '#<Page>'
      end
    end
  end
end
