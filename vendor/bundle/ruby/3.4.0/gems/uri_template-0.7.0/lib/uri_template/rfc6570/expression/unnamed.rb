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

class URITemplate::RFC6570::Expression::Unnamed < URITemplate::RFC6570::Expression

  def self_pair(_, value, max_length = 0,&block)
    if block
      ev = value.map(&block).join(self.class::LIST_CONNECTOR) 
    else
      ev = escape(value)
    end
    cut( ev, max_length ,&block)
  end

  def to_r_source
    vs = @variable_specs.size - 1
    i = 0
    source = regex_builder
    source.group do
      source.escaped_prefix
      @variable_specs.each do | var, expand , max_length |
        last = (vs == i)
        first = (i == 0)
        if expand
          source.group(true) do
            source.separated_list(first) do
              source.group do
                source.character_class('+').reluctant
                source.escaped_pair_connector
              end.length('?')
              source.character_class(max_length)
            end
          end
        else
          source.escaped_separator unless first
          source.group(true) do
            if last
              source.character_class_with_comma(max_length)
            else
              source.character_class(max_length)
            end
          end
        end
        i = i+1
      end
    end.length('?')
    return source.join
  end

private

  def transform_hash(name, hsh, expand , max_length)
    return [] if hsh.none?
    super
  end

  def transform_array(name, ary, expand , max_length)
    return [] if ary.none?
    super
  end

  def after_expand(name, splitted)
    if splitted.none?{|_,b| b }
      return [ [ name, splitted.map{|a,_| a } ] ]
    else
      return [ [ name, splitted ] ]
    end
  end

end
