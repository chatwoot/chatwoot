require 'digest/crc16'

module Digest
  #
  # Implements the CRC16 USB algorithm.
  #
  class CRC16USB < CRC16

    INIT_CRC = 0xffff

    XOR_MASK = 0xffff

  end
end

if RUBY_ENGINE == 'ruby'
  begin; require 'digest/crc16_usb/crc16_usb_ext'; rescue LoadError; end
end
