# coding: utf-8

# import.rb
#
#  Created by James Edward Gray II on 2005-04-26.
#  Copyright 2005 Gray Productions. All rights reserved.
#
#  This is Free Software.  See LICENSE and COPYING for details.

require "highline"
require "forwardable"

#
# <tt>require "highline/import"</tt> adds shortcut methods to Kernel, making
# {HighLine#agree}, {HighLine#ask}, {HighLine#choose} and {HighLine#say}
# globally available.  This is handy for
# quick and dirty input and output.  These methods use HighLine.default_instance
# which is initialized to use <tt>$stdin</tt> and <tt>$stdout</tt> (you are free
# to change this).
# Otherwise, these methods are identical to their {HighLine} counterparts,
# see that class for detailed explanations.
#
module Kernel
  extend Forwardable
  def_instance_delegators :HighLine, :agree, :ask, :choose, :say
end

# When requiring 'highline/import' HighLine adds {#or_ask} to Object so
#   it is globally available.
class Object
  #
  # Tries this object as a _first_answer_ for a HighLine::Question.  See that
  # attribute for details.
  #
  # *Warning*:  This Object will be passed to String() before set.
  #
  # @param args [Array<#to_s>]
  # @param details [lambda] block to be called with the question
  #   instance as argument.
  # @return [String] answer
  def or_ask(*args, &details)
    ask(*args) do |question|
      question.first_answer = String(self)

      yield(question) if details
    end
  end
end
