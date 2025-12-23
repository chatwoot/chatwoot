require 'digest'

module Digest
  #
  # Base class for all CRC algorithms.
  #
  class CRC < Digest::Class

    include Digest::Instance

    # The initial value of the CRC checksum
    INIT_CRC = 0x00

    # The XOR mask to apply to the resulting CRC checksum
    XOR_MASK = 0x00

    # The bit width of the CRC checksum
    WIDTH = 0

    # Default place holder CRC table
    TABLE = [].freeze

    #
    # Calculates the CRC checksum.
    #
    # @param [String] data
    #   The given data.
    #
    # @return [Integer]
    #   The CRC checksum.
    #
    def self.checksum(data)
      crc = self.new
      crc << data

      return crc.checksum
    end

    #
    # Packs the given CRC checksum.
    #
    # @param [Integer] crc
    #   The raw CRC checksum.
    #
    # @return [String]
    #   The packed CRC checksum.
    #
    # @abstract
    #
    def self.pack(crc)
      raise(NotImplementedError,"#{self.class}##{__method__} not implemented")
    end

    #
    # Initializes the CRC checksum.
    #
    def initialize
      @init_crc = self.class.const_get(:INIT_CRC)
      @xor_mask = self.class.const_get(:XOR_MASK)
      @width    = self.class.const_get(:WIDTH)
      @table    = self.class.const_get(:TABLE)

      reset
    end

    #
    # The input block length.
    #
    # @return [1]
    #
    def block_length
      1
    end

    #
    # The length of the digest.
    #
    # @return [Integer]
    #   The length in bytes.
    #
    def digest_length
      (@width / 8.0).ceil
    end

    #
    # Updates the CRC checksum with the given data.
    #
    # @param [String] data
    #   The data to update the CRC checksum with.
    #
    # @abstract
    #
    def update(data)
      raise(NotImplementedError,"#{self.class}##{__method__} not implemented")
    end

    #
    # @see #update
    #
    def <<(data)
      update(data)
      return self
    end

    #
    # Resets the CRC checksum.
    #
    # @return [Integer]
    #   The default value of the CRC checksum.
    #
    def reset
      @crc = @init_crc
    end

    #
    # The resulting CRC checksum.
    #
    # @return [Integer]
    #   The resulting CRC checksum.
    #
    def checksum
      @crc ^ @xor_mask
    end

    #
    # Finishes the CRC checksum calculation.
    #
    # @see pack
    #
    def finish
      self.class.pack(checksum)
    end

  end
end
