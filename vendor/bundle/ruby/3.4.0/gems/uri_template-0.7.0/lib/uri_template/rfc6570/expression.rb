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

    # @private
  class Expression < Token

    include URITemplate::Expression

    attr_reader :variables

    def initialize(vars)
      @variable_specs = vars
      @variables = vars.map(&:first)
      @variables.uniq!
    end

    PREFIX = ''.freeze
    SEPARATOR = ','.freeze
    PAIR_CONNECTOR = '='.freeze
    PAIR_IF_EMPTY = true
    LIST_CONNECTOR = ','.freeze
    BASE_LEVEL = 1

    CHARACTER_CLASS = CHARACTER_CLASSES[:unreserved]

    OPERATOR = ''

    def level
      if @variable_specs.none?{|_,expand,ml| expand || (ml > 0) }
        if @variable_specs.size == 1
          return self.class::BASE_LEVEL
        else
          return 3
        end
      else
        return 4
      end
    end

    def arity
      @variable_specs.size
    end

    def expand( vars )
      result = []
      @variable_specs.each do | var, expand , max_length |
        if Utils.def? vars[var]
          result.push(*expand_one(var, vars[var], expand, max_length))
        end
      end
      if result.any?
        return (self.class::PREFIX + result.join(self.class::SEPARATOR))
      else
        return ''
      end
    end

    def expand_partial( vars )
      result = []
      follow_up = self.class::FOLLOW_UP
      var_specs = []
      @variable_specs.each do | var, expand , max_length |
        if vars.key? var
          unless var_specs.none?
            result.push( follow_up.new( var_specs ) )
            var_specs = []
          end
          unless result.none?
            result.push( Literal.new(self.class::SEPARATOR) )
          end
          one = Array(expand_one(var, vars[var], expand, max_length))
          result.push( Literal.new(one.join(self.class::SEPARATOR)))
        end
        var_specs << [var,expand,max_length]
      end
      if result.none?
        # no literal was emitted so far
        return [ self ]
      end
      unless self.class::PREFIX.empty? || empty_literals?( result )
        result.unshift( Literal.new(self.class::PREFIX) )
      end
      if var_specs.size != 0
        result.push( follow_up.new( var_specs ) )
      end
      return result
    end

    def extract(position,matched)
      name, expand, max_length = @variable_specs[position]
      if matched.nil?
        return [[ name , extracted_nil ]]
      end
      if expand
        it = URITemplate::RegexpEnumerator.new(self.class.hash_extractor(max_length), :rest => :raise)
        if position == 0
          matched = "#{self.class::SEPARATOR}#{matched}"
        end
        splitted = it.each(matched)\
          .map do |match|
            raise match.inspect if match.kind_of? String
            [ decode(match[1]), decode(match[2], false) ]
          end
        return after_expand(name, splitted)
      end

      return [ [ name, decode( matched ) ] ]
    end

    def to_s
      return '{' + self.class::OPERATOR + @variable_specs.map{|name,expand,max_length| name + (expand ? '*': '') + (max_length > 0 ? (':' + max_length.to_s) : '') }.join(',') + '}'
    end

  private

    def expand_one( name, value, expand, max_length)
      if value.kind_of?(Hash) or Utils.pair_array?(value)
        return transform_hash(name, value, expand, max_length)
      elsif value.kind_of? Array
        return transform_array(name, value, expand, max_length)
      else
        return self_pair(name, value, max_length)
      end
    end

    def length_limited?(max_length)
      max_length > 0
    end

    def extracted_nil
      nil
    end

  protected

    module ClassMethods

      def hash_extractors
        @hash_extractors ||= Hash.new{|hsh, key| hsh[key] = generate_hash_extractor(key) }
      end

      def hash_extractor(max_length)
        return hash_extractors[max_length]
      end

      def generate_hash_extractor(max_length)
        source = regex_builder
        source.push('\\A')
        source.escaped_separator
        source.capture do
          source.character_class('+').reluctant
        end
        source.group do
          source.escaped_pair_connector
          source.capture do
            source.character_class(max_length,0).reluctant
          end
        end.length('?')
        source.lookahead do
          source.push '\\z'
          source.push '|'
          source.escaped_separator
          source.push '[^'
            source.escaped_separator
          source.push ']'
        end
        return Regexp.new( source.join , Utils::KCODE_UTF8)
      end

      def regex_builder
        RegexBuilder.new(self)
      end

    end

    extend ClassMethods

    def escape(x)
      Utils.escape_url(Utils.object_to_param(x))
    end

    def unescape(x)
      Utils.unescape_url(x)
    end

    def regex_builder
      self.class.regex_builder
    end

    SPLITTER = /^(,+)|([^,]+)/

    COMMA = ",".freeze

    def decode(x, split = true)
      if x.nil?
        return extracted_nil
      elsif split
        result = []
        # Add a comma if the last character is a comma
        # seems weird but is more compatible than changing
        # the regex.
        x += COMMA if x[-1..-1] == COMMA
        URITemplate::RegexpEnumerator.new(SPLITTER, :rest => :raise).each(x) do |match|
          if match[1]
            next if match[1].size == 1
            result << match[1][0..-3]
          elsif match[2]
            result << unescape(match[2])
          end
        end
        case(result.size)
          when 0 then ''
          when 1 then result.first
          else result
        end
      else
        unescape(x)
      end
    end

    def cut(str,chars)
      if chars > 0
        md = Regexp.compile("\\A#{self.class::CHARACTER_CLASS[:class]}{0,#{chars.to_s}}", Utils::KCODE_UTF8).match(str)
        return md[0]
      else
        return str
      end
    end

    def pair(key, value, max_length = 0, &block)
      ek = key
      if block
        ev = value.map(&block).join(self.class::LIST_CONNECTOR) 
      else
        ev = escape(value)
      end
      if !self.class::PAIR_IF_EMPTY and ev.size == 0
        return ek
      else
        return ek + self.class::PAIR_CONNECTOR + cut( ev, max_length )
      end
    end

    def transform_hash(name, hsh, expand , max_length)
      if expand
        hsh.map{|key,value| pair(escape(key),value) }
      else
        [ self_pair(name,hsh, max_length ){|key,value| escape(key)+self.class::LIST_CONNECTOR+escape(value)} ]
      end
    end

    def transform_array(name, ary, expand , max_length)
      if expand
        ary.map{|value| self_pair(name,value) }
      else
        [ self_pair(name, ary, max_length){|value| escape(value) } ]
      end
    end

    def empty_literals?( list )
      list.none?{|x| x.kind_of?(Literal) && !x.to_s.empty? }
    end
  end

  require 'uri_template/rfc6570/expression/named'
  require 'uri_template/rfc6570/expression/unnamed'

  class Expression::Basic < Expression::Unnamed
    FOLLOW_UP = self
    BULK_FOLLOW_UP = self
  end

  class Expression::Reserved < Expression::Unnamed

    CHARACTER_CLASS = CHARACTER_CLASSES[:unreserved_reserved_pct]
    OPERATOR = '+'.freeze
    BASE_LEVEL = 2
    FOLLOW_UP = self
    BULK_FOLLOW_UP = self

    def escape(x)
      Utils.escape_uri(Utils.object_to_param(x))
    end

    def unescape(x)
      Utils.unescape_uri(x)
    end

    def scheme?
      true
    end

    def host?
      true
    end

  end

  class Expression::Fragment < Expression::Unnamed

    CHARACTER_CLASS = CHARACTER_CLASSES[:unreserved_reserved_pct]
    PREFIX = '#'.freeze
    OPERATOR = '#'.freeze
    BASE_LEVEL = 2
    FOLLOW_UP = Expression::Reserved
    BULK_FOLLOW_UP = Expression::Reserved

    def escape(x)
      Utils.escape_uri(Utils.object_to_param(x))
    end

    def unescape(x)
      Utils.unescape_uri(x)
    end

  end

  class Expression::Label < Expression::Unnamed

    SEPARATOR = '.'.freeze
    PREFIX = '.'.freeze
    OPERATOR = '.'.freeze
    BASE_LEVEL = 3
    FOLLOW_UP = self
    BULK_FOLLOW_UP = self

  end

  class Expression::Path < Expression::Unnamed

    SEPARATOR = '/'.freeze
    PREFIX = '/'.freeze
    OPERATOR = '/'.freeze
    BASE_LEVEL = 3
    FOLLOW_UP = self
    BULK_FOLLOW_UP = self

    def starts_with_slash?
      true
    end

  end

  class Expression::PathParameters < Expression::Named

    SEPARATOR = ';'.freeze
    PREFIX = ';'.freeze
    PAIR_IF_EMPTY = false
    OPERATOR = ';'.freeze
    BASE_LEVEL = 3
    FOLLOW_UP = self
    BULK_FOLLOW_UP = self

  end

  class Expression::FormQueryContinuation < Expression::Named

    SEPARATOR = '&'.freeze
    PREFIX = '&'.freeze
    OPERATOR = '&'.freeze
    BASE_LEVEL = 3
    FOLLOW_UP = Expression::Basic
    BULK_FOLLOW_UP = self
  end

  class Expression::FormQuery < Expression::Named

    SEPARATOR = '&'.freeze
    PREFIX = '?'.freeze
    OPERATOR = '?'.freeze
    BASE_LEVEL = 3
    FOLLOW_UP = Expression::Basic
    BULK_FOLLOW_UP = Expression::FormQueryContinuation

  end


  # @private
  OPERATORS = {
    ''  => Expression::Basic,
    '+' => Expression::Reserved,
    '#' => Expression::Fragment,
    '.' => Expression::Label,
    '/' => Expression::Path,
    ';' => Expression::PathParameters,
    '?' => Expression::FormQuery,
    '&' => Expression::FormQueryContinuation
  }

end
