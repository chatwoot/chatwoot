require 'digest/crc32'

module Digest
  #
  # Implements the CRC32 Jam algorithm.
  #
  class CRC32Jam < CRC32

    INIT_XOR = 0xffffffff

    INIT_CRC = 0x0 ^ INIT_XOR

    XOR_MASK = 0x00000000

  end
end
