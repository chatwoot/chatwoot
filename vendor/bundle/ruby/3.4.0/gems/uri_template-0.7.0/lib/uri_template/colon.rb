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

require 'forwardable'

require 'uri_template'
require 'uri_template/utils'

module URITemplate

# A colon based template denotes variables with a colon.
#
# This template type is somewhat compatible with sinatra.
#
# @example
#   tpl = URITemplate::Colon.new('/foo/:bar')
#   tpl.extract('/foo/baz') #=> {'bar'=>'baz'}
#   tpl.expand('bar'=>'boom') #=> '/foo/boom'
#
class Colon

  include URITemplate

  VAR = /(?:\{:(\w+)\}|:(\w+)(?!\w)|\*)/u

  class InvalidValue < StandardError

    include URITemplate::InvalidValue

    attr_reader :variable, :value

    def initialize(variable, value)
      @variable = variable
      @value = value
      super(generate_message())
    end

    class SplatIsNotAnArray < self
    end

  protected

    def generate_message()
      return "The template variable " + variable.inspect + " cannot expand the given value "+ value.inspect
    end

  end

  class Token

    class Variable < self

      include URITemplate::Expression

      attr_reader :name

      def initialize(name)
        @name = name
        @variables = [name]
      end

      def expand(vars)
        return Utils.escape_url(Utils.object_to_param(vars[name]))
      end

      def to_r
        return '([^/]*?)'
      end

      def to_s
        return ":#{name}"
      end

    end

    class Splat < Variable

      SPLAT = 'splat'.freeze

      attr_reader :index

      def initialize(index)
        @index = index
        super(SPLAT)
      end

      def expand(vars)
        var = vars[name]
        if Array === var
          return Utils.escape_uri(Utils.object_to_param(var[index]))
        else
          raise InvalidValue::SplatIsNotAnArray.new(name,var)
        end
      end

      def to_r
        return '(.+?)'
      end

    end

    class Static < self

      include URITemplate::Literal

      def initialize(str)
        @string = str
      end

      def expand(_)
        return @string
      end

      def to_r
        return Regexp.escape(@string)
      end

    end

  end

  attr_reader :pattern

  # Tries to convert the value into a colon-template.
  # @example
  #   URITemplate::Colon.try_convert('/foo/:bar/').pattern #=> '/foo/:bar/'
  #   URITemplate::Colon.try_convert(URITemplate.new(:rfc6570, '/foo/{bar}/')).pattern #=> '/foo/{:bar}/'
  def self.try_convert(x)
    if x.kind_of? String
      return new(x)
    elsif x.kind_of? self
      return x
    elsif x.kind_of? URITemplate::RFC6570 and x.level == 1
      return new( x.pattern.gsub(/\{(.*?)\}/u){ "{:#{$1}}" } )
    else
      return nil
    end
  end

  def initialize(pattern)
    raise ArgumentError,"Expected a String but got #{pattern.inspect}" unless pattern.kind_of? String
    @pattern = pattern
  end

  # Extracts variables from an uri.
  #
  # @param uri [String]
  # @return nil,Hash
  def extract(uri)
    md = self.to_r.match(uri)
    return nil unless md
    result = {}
    splat = []
    self.tokens.select{|tk| tk.kind_of? URITemplate::Expression }.each_with_index do |tk,i|
      if tk.kind_of? Token::Splat
        splat << md[i+1]
        result['splat'] = splat unless result.key? 'splat'
      else
        result[tk.name] = Utils.unescape_url( md[i+1] )
      end
    end
    if block_given?
      return yield(result)
    end
    return result
  end

  def type
    :colon
  end

  def to_r
    @regexp ||= Regexp.new('\A' + tokens.map(&:to_r).join + '\z', Utils::KCODE_UTF8)
  end

  def tokens
    @tokens ||= tokenize!
  end

protected

  def tokenize!
    number_of_splats = 0
    RegexpEnumerator.new(VAR).each(@pattern).map{|x|
      if x.kind_of? String
        Token::Static.new(Utils.escape_uri(x))
      elsif x[0] == '*'
        n = number_of_splats
        number_of_splats = number_of_splats + 1
        Token::Splat.new(n)
      else
        # TODO: when rubinius supports ambigious names this could be replaced with x['name'] *sigh*
        Token::Variable.new(x[1] || x[2])
      end
    }.to_a
  end

end
end
