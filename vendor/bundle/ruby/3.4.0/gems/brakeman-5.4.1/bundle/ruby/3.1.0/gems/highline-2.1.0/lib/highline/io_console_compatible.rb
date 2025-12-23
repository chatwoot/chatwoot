# coding: utf-8

require "stringio"
require "tempfile"

#
# On tests, we try to simulate input output with
# StringIO, Tempfile and File objects.
#
# For this to be accomplished, we have to do some
# tweaking so that they respond adequately to the
# called methods during tests.
#

module IOConsoleCompatible
  def getch
    getc
  end

  attr_accessor :echo

  def winsize
    [24, 80]
  end
end

class Tempfile
  include IOConsoleCompatible
end

class File
  include IOConsoleCompatible
end

class StringIO
  include IOConsoleCompatible
end
