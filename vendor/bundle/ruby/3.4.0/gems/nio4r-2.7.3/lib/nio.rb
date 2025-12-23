# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2017, by Tony Arcieri.
# Copyright, 2013, by Stephen von Takach.
# Copyright, 2013, by Per Lundberg.
# Copyright, 2014, by Marek Kowalcze.
# Copyright, 2016, by Upekshe Jayasekera.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2021, by Jun Jiang.

require "socket"
require "nio/version"

# New I/O for Ruby
module NIO
  # NIO implementation, one of the following (as a string):
  # * select: in pure Ruby using Kernel.select
  # * libev: as a C extension using libev
  # * java: using Java NIO
  def self.engine
    ENGINE
  end

  def self.pure?(env = ENV)
    # The user has explicitly opted in to non-native implementation:
    if env["NIO4R_PURE"] == "true"
      return true
    end

    # Native Ruby on Windows is not supported:
    if (Gem.win_platform? && !defined?(JRUBY_VERSION))
      return true
    end

    # M1 native extension is crashing on M1 (arm64):
    # if RUBY_PLATFORM =~ /darwin/ && RUBY_PLATFORM =~ /arm64/
    #   return true
    # end

    return false
  end
end

if NIO.pure?
  require "nio/monitor"
  require "nio/selector"
  require "nio/bytebuffer"
  NIO::ENGINE = "ruby"
else
  require "nio4r_ext"

  if defined?(JRUBY_VERSION)
    require "java"
    require "jruby"
    org.nio4r.Nio4r.new.load(JRuby.runtime, false)
    NIO::ENGINE = "java"
  else
    NIO::ENGINE = "libev"
  end
end
