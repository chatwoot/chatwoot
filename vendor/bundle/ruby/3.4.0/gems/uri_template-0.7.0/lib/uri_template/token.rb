# -*- encoding : utf-8 -*-
# The MIT License (MIT)
#
# Copyright (c) 2011-2014 Hannes Georg
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# This should make it possible to do basic analysis independently from the concrete type.
# Usually the submodules {URITemplate::Literal} and {URITemplate::Expression} are used.
#
# @abstract
module URITemplate::Token

  EMPTY_ARRAY = [].freeze

  # The variable names used in this token.
  #
  # @return [Array<String>]
  def variables
    EMPTY_ARRAY
  end

  # Number of variables in this token
  def size
    variables.size
  end

  def starts_with_slash?
    false
  end

  def ends_with_slash?
    false
  end

  def scheme?
    false
  end

  def host?
    false
  end

  # @abstract
  def expand(variables)
    raise "Please implement #expand(variables) on #{self.class.inspect}."
  end

  # @abstract
  def expand_partial(variables)
    raise "Please implement #expand_partial(variables) on #{self.class.inspect}."
  end

  # @abstract
  def to_s
    raise "Please implement #to_s on #{self.class.inspect}."
  end

end
