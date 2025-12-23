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

require 'uri_template/rfc6570'

class URITemplate::RFC6570

  class RegexBuilder

    def initialize(expression_class)
      @expression_class = expression_class
      @source = []
    end

    def <<(arg)
      @source << arg
      self
    end

    def push(*args)
      @source.push(*args)
      self
    end

    def escaped_pair_connector
      self << Regexp.escape(@expression_class::PAIR_CONNECTOR)
    end

    def escaped_separator
      self << Regexp.escape(@expression_class::SEPARATOR)
    end

    def escaped_prefix
      self << Regexp.escape(@expression_class::PREFIX)
    end

    def join
      return @source.join
    end

    def length(*args)
      self << format_length(*args)
    end

    def character_class_with_comma(max_length=0, min = 0)
      self << @expression_class::CHARACTER_CLASS[:class_with_comma] << format_length(max_length, min)
    end

    def character_class(max_length=0, min = 0)
      self << @expression_class::CHARACTER_CLASS[:class] << format_length(max_length, min)
    end

    def reluctant
      self << '?'
    end

    def group(capture = false)
      self << '('
      self << '?:' unless capture
      yield
      self << ')'
    end

    def negative_lookahead
      self << '(?!'
      yield
      self << ')'
    end

    def lookahead
      self << '(?='
      yield
      self << ')'
    end

    def capture(&block)
      group(true, &block)
    end

    def separated_list(first = true, length = 0, min = 1, &block)
      if first
        yield
        min -= 1
      end
      self.push('(?:').escaped_separator
      yield
      self.push(')').length(length, min)
    end

  private

    def format_length(len, min = 0)
      return len if len.kind_of? String
      return '{'+min.to_s+','+len.to_s+'}' if len.kind_of?(Numeric) and len > 0
      return '*' if min == 0
      return '+' if min == 1
      return '{'+min.to_s+',}'
    end


  end

end
