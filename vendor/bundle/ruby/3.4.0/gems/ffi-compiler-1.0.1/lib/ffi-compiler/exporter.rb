require 'ffi'

load ARGV[0]
FFI.exporter.dump(ARGV[1])
