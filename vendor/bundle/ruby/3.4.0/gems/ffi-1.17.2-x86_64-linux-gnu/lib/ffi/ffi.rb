#
# Copyright (C) 2008-2010 JRuby project
#
# This file is part of ruby-ffi.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the Ruby FFI project nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'ffi/compat'
require 'ffi/platform'
require 'ffi/data_converter'
require 'ffi/types'
require 'ffi/library_path'
require 'ffi/library'
require 'ffi/errno'
require 'ffi/abstract_memory'
require 'ffi/pointer'
require 'ffi/memorypointer'
require 'ffi/struct'
require 'ffi/union'
require 'ffi/managedstruct'
require 'ffi/callback'
require 'ffi/io'
require 'ffi/autopointer'
require 'ffi/variadic'
require 'ffi/enum'
require 'ffi/version'
require 'ffi/function'

module FFI
  module ModernForkTracking
    def _fork
      pid = super
      if pid == 0
        FFI._async_cb_dispatcher_atfork_child
      end
      pid
    end
  end

  module LegacyForkTracking
    module KernelExt
      def fork
        if block_given?
          super do
            FFI._async_cb_dispatcher_atfork_child
            yield
          end
        else
          pid = super
          FFI._async_cb_dispatcher_atfork_child if pid.nil?
          pid
        end
      end
    end

    module KernelExtPrivate
      include KernelExt
      private :fork
    end

    module IOExt
      def popen(*args)
        return super unless args[0] == '-'

        super(*args) do |pipe|
          FFI._async_cb_dispatcher_atfork_child if pipe.nil?
          yield pipe
        end
      end
      ruby2_keywords :popen if respond_to?(:ruby2_keywords)
    end
  end

  if Process.respond_to?(:_fork)
    # The nice Ruby 3.1+ way of doing things
    ::Process.singleton_class.prepend(ModernForkTracking)
  elsif Process.respond_to?(:fork)
    # Barf. Old CRuby.
    # Most of the inspiration for how to do this was stolen from ActiveSupport.
    ::Object.prepend(LegacyForkTracking::KernelExtPrivate)
    ::Object.singleton_class.prepend(LegacyForkTracking::KernelExt)
    ::Kernel.prepend(LegacyForkTracking::KernelExtPrivate)
    ::Kernel.singleton_class.prepend(LegacyForkTracking::KernelExt)
    ::IO.singleton_class.prepend(LegacyForkTracking::IOExt)
  end
end
