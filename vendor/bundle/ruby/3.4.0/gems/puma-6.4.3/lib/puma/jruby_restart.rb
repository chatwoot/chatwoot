# frozen_string_literal: true

require 'ffi'

module Puma
  module JRubyRestart
    extend FFI::Library
    ffi_lib 'c'

    attach_function :execlp, [:string, :varargs], :int
    attach_function :chdir, [:string], :int
    attach_function :fork, [], :int
    attach_function :exit, [:int], :void
    attach_function :setsid, [], :int

    def self.chdir_exec(dir, argv)
      chdir(dir)
      cmd = argv.first
      argv = ([:string] * argv.size).zip(argv)
      argv.flatten!
      argv << :string
      argv << nil
      execlp(cmd, *argv)
      raise SystemCallError.new(FFI.errno)
    end
  end
end
