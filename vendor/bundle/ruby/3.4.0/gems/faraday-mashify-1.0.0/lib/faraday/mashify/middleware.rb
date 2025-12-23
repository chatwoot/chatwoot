# frozen_string_literal: true

module Faraday
  module Mashify
    # Public: Converts parsed response bodies to a Hashie::Mash if they were of Hash or Array type.
    class Middleware < Faraday::Middleware
      # @!attribute [rw] mash_class
      #   @return [Class]
      attr_accessor :mash_class

      class << self
        # @!attribute [rw] mash_class
        #   @return [Class]
        attr_accessor :mash_class
      end

      # @param app [Proc]
      # @param options [Hash]
      # @option options [Class] :mash_class Responses are wrapped in this class (default is `::Hashie::Mash`)
      def initialize(app = nil, options = {})
        super
        self.mash_class = options[:mash_class] || self.class.mash_class || ::Hashie::Mash
      end

      # This method will be called when the response is being processed.
      # You can alter it as you like, accessing things like response_body, response_headers, and more.
      # Refer to Faraday::Env for a list of accessible fields:
      # https://github.com/lostisland/faraday/blob/main/lib/faraday/options/env.rb
      #
      # @param env [Faraday::Env] the environment of the response being processed.
      def on_complete(env)
        env[:body] = parse(env[:body])
      end

      private

      def parse(body)
        case body
        when Hash
          mash_class.new(body)
        when Array
          body.map { |item| parse(item) }
        else
          body
        end
      end
    end
  end
end
