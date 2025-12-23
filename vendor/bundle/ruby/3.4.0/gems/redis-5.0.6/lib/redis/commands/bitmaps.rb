# frozen_string_literal: true

class Redis
  module Commands
    module Bitmaps
      # Sets or clears the bit at offset in the string value stored at key.
      #
      # @param [String] key
      # @param [Integer] offset bit offset
      # @param [Integer] value bit value `0` or `1`
      # @return [Integer] the original bit value stored at `offset`
      def setbit(key, offset, value)
        send_command([:setbit, key, offset, value])
      end

      # Returns the bit value at offset in the string value stored at key.
      #
      # @param [String] key
      # @param [Integer] offset bit offset
      # @return [Integer] `0` or `1`
      def getbit(key, offset)
        send_command([:getbit, key, offset])
      end

      # Count the number of set bits in a range of the string value stored at key.
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [Integer] the number of bits set to 1
      def bitcount(key, start = 0, stop = -1)
        send_command([:bitcount, key, start, stop])
      end

      # Perform a bitwise operation between strings and store the resulting string in a key.
      #
      # @param [String] operation e.g. `and`, `or`, `xor`, `not`
      # @param [String] destkey destination key
      # @param [String, Array<String>] keys one or more source keys to perform `operation`
      # @return [Integer] the length of the string stored in `destkey`
      def bitop(operation, destkey, *keys)
        keys.flatten!(1)
        command = [:bitop, operation, destkey]
        command.concat(keys)
        send_command(command)
      end

      # Return the position of the first bit set to 1 or 0 in a string.
      #
      # @param [String] key
      # @param [Integer] bit whether to look for the first 1 or 0 bit
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [Integer] the position of the first 1/0 bit.
      #                  -1 if looking for 1 and it is not found or start and stop are given.
      def bitpos(key, bit, start = nil, stop = nil)
        raise(ArgumentError, 'stop parameter specified without start parameter') if stop && !start

        command = [:bitpos, key, bit]
        command << start if start
        command << stop if stop
        send_command(command)
      end
    end
  end
end
