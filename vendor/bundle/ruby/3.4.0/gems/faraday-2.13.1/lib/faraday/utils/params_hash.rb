# frozen_string_literal: true

module Faraday
  module Utils
    # A hash with stringified keys.
    class ParamsHash < Hash
      def [](key)
        super(convert_key(key))
      end

      def []=(key, value)
        super(convert_key(key), value)
      end

      def delete(key)
        super(convert_key(key))
      end

      def include?(key)
        super(convert_key(key))
      end

      alias has_key? include?
      alias member? include?
      alias key? include?

      def update(params)
        params.each do |key, value|
          self[key] = value
        end
        self
      end
      alias merge! update

      def merge(params)
        dup.update(params)
      end

      def replace(other)
        clear
        update(other)
      end

      def merge_query(query, encoder = nil)
        return self unless query && !query.empty?

        update((encoder || Utils.default_params_encoder).decode(query))
      end

      def to_query(encoder = nil)
        (encoder || Utils.default_params_encoder).encode(self)
      end

      private

      def convert_key(key)
        key.to_s
      end
    end
  end
end
