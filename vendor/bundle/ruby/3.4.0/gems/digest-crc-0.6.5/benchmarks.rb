#!/usr/bin/env ruby
require 'benchmark'
$LOAD_PATH.unshift(File.expand_path('../ext',__FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib',__FILE__))

CRCs = {
  'crc1'          => 'CRC1',
  'crc5'          => 'CRC5',
  'crc8'          => 'CRC8',
  'crc8_1wire'    => 'CRC81Wire',
  'crc15'         => 'CRC15',
  'crc16'         => 'CRC16',
  'crc16_ccitt'   => 'CRC16CCITT',
  'crc16_dnp'     => 'CRC16DNP',
  'crc16_genibus' => 'CRC16Genibus',
  'crc16_modbus'  => 'CRC16Modbus',
  'crc16_qt'      => 'CRC16QT',
  'crc16_usb'     => 'CRC16USB',
  'crc16_x_25'    => 'CRC16X25',
  'crc16_xmodem'  => 'CRC16XModem',
  'crc16_zmodem'  => 'CRC16ZModem',
  'crc24'         => 'CRC24',
  'crc32'         => 'CRC32',
  'crc32_bzip2'   => 'CRC32BZip2',
  'crc32c'        => 'CRC32c',
  'crc32_jam'     => 'CRC32Jam',
  'crc32_mpeg'    => 'CRC32Mpeg',
  'crc32_posix'   => 'CRC32POSIX',
  'crc32_xfer'    => 'CRC32XFER',
  'crc64'         => 'CRC64',
  'crc64_jones'   => 'CRC64Jones',
  'crc64_xz'      => 'CRC64XZ',
}

puts "Loading Digest::CRC classes ..."
CRCs.each_key { |crc| require "digest/#{crc}" }

N = 1000
BLOCK_SIZE = 8 * 1024

puts "Generating #{N} #{BLOCK_SIZE / 1024}Kb lengthed strings ..."
SAMPLES = Array.new(N) do
  Array.new(BLOCK_SIZE) { rand(256).chr }.join
end

puts "Benchmarking Digest::CRC classes ..."
Benchmark.bm(27) do |b|
  CRCs.each_value do |crc|
    crc_class = Digest.const_get(crc)
    crc = crc_class.new

    b.report("#{crc_class}#update") do
      SAMPLES.each do |sample|
        crc.update(sample)
      end
    end
  end
end
