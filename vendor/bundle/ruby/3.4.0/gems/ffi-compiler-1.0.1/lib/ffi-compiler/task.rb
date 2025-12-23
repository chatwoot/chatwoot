require 'rake'
require 'rake/tasklib'
require 'rake/clean'
require 'ffi'
require 'tmpdir'
require 'rbconfig'
require_relative 'compile_task'

module FFI
  module Compiler
    class Task < CompileTask
      warn "#{self} is deprecated"
    end
  end
end
