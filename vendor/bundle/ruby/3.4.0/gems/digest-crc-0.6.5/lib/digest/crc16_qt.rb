require 'digest/crc16_x_25'

module Digest
  #
  # Implements the CRC16_CCITT algorithm used in QT algorithms.
  #
  # @note Is exactly the same as the CRC16 X-25 algorithm.
  #
  class CRC16QT < CRC16X25
  end
end
