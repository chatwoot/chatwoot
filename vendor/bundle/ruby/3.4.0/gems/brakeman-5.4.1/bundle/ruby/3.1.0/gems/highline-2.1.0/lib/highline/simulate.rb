# coding: utf-8

#--
# simulate.rb
#
#  Created by Andy Rossmeissl on 2012-04-29.
#  Copyright 2005 Gray Productions. All rights reserved.
#
#  This is Free Software.  See LICENSE and COPYING for details.
#
# adapted from https://gist.github.com/194554

class HighLine
  # Simulates Highline input for use in tests.
  class Simulate
    # Creates a simulator with an array of Strings as a script
    # @param strings [Array<String>] preloaded string to be used
    #   as input buffer when simulating.
    def initialize(strings)
      @strings = strings
    end

    # Simulate StringIO#gets by shifting a string off of the script
    def gets
      @strings.shift
    end

    # Simulate StringIO#getbyte by shifting a single character off of
    # the next line of the script
    def getbyte
      line = gets
      return if line.empty?

      char = line.slice! 0
      @strings.unshift line
      char
    end

    # The simulator handles its own EOF
    def eof?
      false
    end

    # A wrapper method that temporarily replaces the Highline
    # instance in HighLine.default_instance with an instance of this object
    # for the duration of the block
    #
    # @param strings [String] preloaded string buffer that
    #   will feed the input operations when simulating.

    def self.with(*strings)
      @input = HighLine.default_instance.instance_variable_get :@input
      HighLine.default_instance.instance_variable_set :@input, new(strings)
      yield
    ensure
      HighLine.default_instance.instance_variable_set :@input, @input
    end
  end
end
