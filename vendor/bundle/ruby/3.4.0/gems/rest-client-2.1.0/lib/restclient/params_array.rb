module RestClient

  # The ParamsArray class is used to represent an ordered list of [key, value]
  # pairs. Use this when you need to include a key multiple times or want
  # explicit control over parameter ordering.
  #
  # Most of the request payload & parameter functions normally accept a Hash of
  # keys => values, which does not allow for duplicated keys.
  #
  # @see RestClient::Utils.encode_query_string
  # @see RestClient::Utils.flatten_params
  #
  class ParamsArray
    include Enumerable

    # @param array [Array<Array>] An array of parameter key,value pairs. These
    #   pairs may be 2 element arrays [key, value] or single element hashes
    #   {key => value}. They may also be single element arrays to represent a
    #   key with no value.
    #
    # @example
    #   >> ParamsArray.new([[:foo, 123], [:foo, 456], [:bar, 789]])
    #   This will be encoded as "foo=123&foo=456&bar=789"
    #
    # @example
    #   >> ParamsArray.new({foo: 123, bar: 456})
    #   This is valid, but there's no reason not to just use the Hash directly
    #   instead of a ParamsArray.
    #
    #
    def initialize(array)
      @array = process_input(array)
    end

    def each(*args, &blk)
      @array.each(*args, &blk)
    end

    def empty?
      @array.empty?
    end

    private

    def process_input(array)
      array.map {|v| process_pair(v) }
    end

    # A pair may be:
    # - A single element hash, e.g. {foo: 'bar'}
    # - A two element array, e.g. ['foo', 'bar']
    # - A one element array, e.g. ['foo']
    #
    def process_pair(pair)
      case pair
      when Hash
        if pair.length != 1
          raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
        end
        pair.to_a.fetch(0)
      when Array
        if pair.length > 2
          raise ArgumentError.new("Bad # of fields for pair: #{pair.inspect}")
        end
        [pair.fetch(0), pair[1]]
      else
        # recurse, converting any non-array to an array
        process_pair(pair.to_a)
      end
    end
  end
end
