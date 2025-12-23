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

class Expression::Named < Expression

  alias self_pair pair

  def to_r_source
    source = regex_builder
    source.group do
      source.escaped_prefix
      first = true
      @variable_specs.each do | var, expand , max_length |
        if expand
          source.capture do
            source.separated_list(first) do
              source.character_class('+')\
                .escaped_pair_connector\
                .character_class_with_comma(max_length)
            end
          end
        else
          source.group do
            source.escaped_separator unless first
            source << Regexp.escape(var)
            source.group do
              source.escaped_pair_connector
              source.capture do
                source.character_class_with_comma(max_length)
              end
              source << '|' unless self.class::PAIR_IF_EMPTY
            end
          end.length('?')
        end
        first = false
      end
    end.length('?')
    return source.join
  end

  def expand_partial( vars )
    result = []
    rest   = []
    defined = false
    @variable_specs.each do | var, expand , max_length |
      if vars.key? var
        if Utils.def? vars[var]
          if result.any? && !self.class::SEPARATOR.empty?
            result.push( Literal.new(self.class::SEPARATOR) )
          end
          one = expand_one(var, vars[var], expand, max_length)
          result.push( Literal.new(Array(one).join(self.class::SEPARATOR)) )
        end
        if expand
          rest << [var, expand, max_length]
        else
          result.push( self.class::FOLLOW_UP.new([[var,expand,max_length]]) )
        end
      else
        rest.push( [var,expand,max_length] )
      end
    end
    if result.any?
      unless self.class::PREFIX.empty? || empty_literals?( result )
        result.unshift( Literal.new(self.class::PREFIX) )
      end
      result.push( self.class::BULK_FOLLOW_UP.new(rest) ) if rest.size != 0
      return result
    else
      return [ self ]
    end
  end

private

  def extracted_nil
    self.class::PAIR_IF_EMPTY ? nil : ""
  end

  def after_expand(name, splitted)
    result = URITemplate::Utils.pair_array_to_hash2( splitted )
    if result.size == 1 && result[0][0] == name
      return result
    else
      return [ [ name , result ] ]
    end
  end

end
end
