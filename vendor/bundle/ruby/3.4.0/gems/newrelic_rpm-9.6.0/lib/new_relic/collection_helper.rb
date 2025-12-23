# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module CollectionHelper
    DEFAULT_TRUNCATION_SIZE = 16 * 1024
    DEFAULT_ARRAY_TRUNCATION_SIZE = 128
    # Transform parameter hash into a hash whose values are strictly
    # strings
    def normalize_params(params)
      case params
        when Hash
          # Optimize for empty hash since that is often what this is called with.
          return params if params.empty?

          new_params = {}
          params.each do |key, value|
            new_params[truncate(normalize_params(key), 64)] = normalize_params(value)
          end
          new_params
        when Symbol, FalseClass, TrueClass, nil
          params
        when Numeric
          truncate(params.to_s)
        when String
          truncate(params)
        when Array
          params.first(DEFAULT_ARRAY_TRUNCATION_SIZE).map { |item| normalize_params(item) }
        else
          truncate(flatten(params))
      end
    end

    private

    # Convert any kind of object to a short string.
    def flatten(object)
      case object
        when nil then ''
        when object.instance_of?(String) then object
        when String then String.new(object) # convert string subclasses to strings
        else +"#<#{object.class}>"
      end
    end

    def truncate(string, len = DEFAULT_TRUNCATION_SIZE)
      case string
      when Symbol then string
      when nil then EMPTY_STR
      when String
        real_string = flatten(string)
        if real_string.size > len
          real_string = real_string.slice(0...len)
          real_string << '...'
        end
        real_string
      else
        truncate(flatten(string), len)
      end
    end
  end
end
