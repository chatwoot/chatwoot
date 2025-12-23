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

# A base module for all implementations of a uri template.
module URITemplate

  # Helper module which defines class methods for all uri template
  # classes.
  module ClassMethods
    # Tries to convert the given argument into an {URITemplate}.
    # Returns nil if this fails.
    #
    # @return [nil|{URITemplate}]
    def try_convert(x)
      if x.kind_of? self
        return x
      elsif x.kind_of? String
        return self.new(x)
      else
        return nil
      end
    end

    # Same as {.try_convert} but raises an ArgumentError when the given argument could not be converted.
    # 
    # @raise ArgumentError if the argument is unconvertable
    # @return {URITemplate}
    def convert(x)
      o = self.try_convert(x)
      if o.nil?
        raise ArgumentError, "Expected to receive something that can be converted into a URITemplate of type #{self.inspect}, but got #{x.inspect}"
      end
      return o
    end

    def included(base)
      base.extend(ClassMethods)
    end
  end

  extend ClassMethods

  # @api private
  SCHEME_REGEX = /\A[a-z]+:/i.freeze

  # @api private
  HOST_REGEX = /\A(?:[a-z]+:)?\/\/[^\/]+/i.freeze

  # @api private
  URI_SPLIT = /\A(?:([a-z]+):)?(?:\/\/)?([^\/]+)?/i.freeze

  autoload :Utils, 'uri_template/utils'
  autoload :Token, 'uri_template/token'
  autoload :Literal, 'uri_template/literal'
  autoload :Expression, 'uri_template/expression'
  autoload :RFC6570, 'uri_template/rfc6570'
  autoload :Colon, 'uri_template/colon'

  # A hash with all available implementations.
  # @see resolve_class
  VERSIONS = {
    :rfc6570 => :RFC6570,
    :default => :RFC6570,
    :colon => :Colon,
    :latest => :RFC6570
  }

  # Looks up which implementation to use.
  # Extracts all symbols from args and looks up the first in {VERSIONS}.
  #
  # @return Array an array of the class to use and the unused parameters.
  # 
  # @example
  #   URITemplate.resolve_class() #=> [ URITemplate::RFC6570, [] ]
  #   URITemplate.resolve_class(:colon) #=> [ URITemplate::Colon, [] ]
  #   URITemplate.resolve_class("template",:rfc6570) #=> [ URITemplate::RFC6570, ["template"] ]
  # 
  # @raise ArgumentError when no class was found.
  #
  def self.resolve_class(*args)
    symbols, rest = args.partition{|x| x.kind_of? Symbol }
    version = symbols.fetch(0, :default)
    raise ArgumentError, "Unknown template version #{version.inspect}, defined versions: #{VERSIONS.keys.inspect}" unless VERSIONS.key?(version)
    return self.const_get(VERSIONS[version]), rest
  end

  # Creates an uri template using an implementation.
  # The args should at least contain a pattern string.
  # Symbols in the args are used to determine the actual implementation.
  #
  # @example
  #   tpl = URITemplate.new('{x}') # a new template using the default implementation
  #   tpl.expand('x'=>'y') #=> 'y'
  #
  # @example
  #   tpl = URITemplate.new(:colon,'/:x') # a new template using the colon implementation
  # 
  def self.new(*args)
    klass, rest = resolve_class(*args)
    return klass.new(*rest)
  end

  # Tries to coerce two URITemplates into a common representation.
  # Returns an array with two {URITemplate}s and two booleans indicating which of the two were converted or raises an ArgumentError.
  #
  # @example
  #   URITemplate.coerce( URITemplate.new(:rfc6570,'{x}'), '{y}' ) #=> [URITemplate.new(:rfc6570,'{x}'), URITemplate.new(:rfc6570,'{y}'), false, true]
  #   URITemplate.coerce( '{y}', URITemplate.new(:rfc6570,'{x}') ) #=> [URITemplate.new(:rfc6570,'{y}'), URITemplate.new(:rfc6570,'{x}'), true, false]
  #
  # @return [Tuple<URITemplate,URITemplate,Bool,Bool>]
  def self.coerce(a,b)
    if a.kind_of? URITemplate
      if a.class == b.class
        return [a,b,false,false]
      end
      b_as_a = a.class.try_convert(b)
      if b_as_a
        return [a,b_as_a,false,true]
      end
    end
    if b.kind_of? URITemplate
      a_as_b = b.class.try_convert(a)
      if a_as_b
        return [a_as_b, b, true, false]
      end
    end
    bc = self.try_convert(b)
    if bc.kind_of? URITemplate
      a_as_b = bc.class.try_convert(a)
      if a_as_b
        return [a_as_b, bc, true, true]
      end
    end
    raise ArgumentError, "Expected at least on URITemplate, but got #{a.inspect} and #{b.inspect}" unless a.kind_of? URITemplate or b.kind_of? URITemplate
    raise ArgumentError, "Cannot coerce #{a.inspect} and #{b.inspect} into a common representation."
  end

  # Applies a method to a URITemplate with another URITemplate as argument.
  # This is a useful shorthand since both URITemplates are automatically coerced.
  #
  # @example
  #   tpl = URITemplate.new('foo')
  #   URITemplate.apply( tpl, :/, 'bar' ).pattern #=> 'foo/bar'
  #   URITemplate.apply( 'baz', :/, tpl ).pattern #=> 'baz/foo'
  #   URITemplate.apply( 'bla', :/, 'blub' ).pattern #=> 'bla/blub'
  # 
  def self.apply(a, method, b, *args)
    a,b,_,_ = self.coerce(a,b)
    a.send(method,b,*args)
  end

  # @api private
  def self.coerce_first_arg(meth)
    alias_method( (meth.to_s + '_without_coercion').to_sym , meth )
    class_eval(<<-RUBY)
def #{meth}(other, *args, &block)
  this, other, this_converted, _ = URITemplate.coerce( self, other )
  if this_converted
    return this.#{meth}(other,*args, &block)
  end
  return #{meth}_without_coercion(other,*args, &block)
end
RUBY
  end

  # A base class for all errors which will be raised upon invalid syntax.
  module Invalid
  end

  # A base class for all errors which will be raised when a variable value
  # is not allowed for a certain expansion.
  module InvalidValue
  end

  # Expands this uri template with the given variables.
  # The variables should be converted to strings using {Utils#object_to_param}.
  #
  # The keys in the variables hash are converted to
  # strings in order to support the Ruby 1.9 hash syntax.
  #
  # If the variables are given as an array, they will be matched against the variables in the template based on their order.
  #
  # @raise {Unconvertable} if a variable could not be converted to a string.
  # @raise {InvalidValue} if a value is not suiteable for a certain variable ( e.g. a string when a list is expected ).
  #
  # @param variables [#map, Array]
  # @return String
  def expand(variables = {})
    variables = normalize_variables(variables)
    tokens.map{|part|
      part.expand(variables)
    }.join
  end

  # Works like #expand with two differences:
  #
  #  - the result is a uri template instead of string
  #  - undefined variables are left in the template
  # 
  # @see {#expand}
  # @param variables [#map, Array]
  # @return [URITemplate]
  def expand_partial(variables = {})
    variables = normalize_variables(variables)
    self.class.new(tokens.map{|part|
      part.expand_partial(variables)
    }.flatten(1))
  end

  def normalize_variables( variables )
    raise ArgumentError, "Expected something that responds to :map, but got: #{variables.inspect}" unless variables.respond_to? :map
    if variables.kind_of?(Array)
      return Hash[self.variables.zip(variables)]
    else
      # Stringify variables
      arg = variables.map{ |k, v| [k.to_s, v] }
      if arg.any?{|elem| !elem.kind_of?(Array) }
        raise ArgumentError, "Expected the output of variables.map to return an array of arrays but got #{arg.inspect}"
      end
      return Hash[arg]
    end
  end

  private :normalize_variables

  # @abstract
  # Returns the type of this template. The type is a symbol which can be used in {.resolve_class} to resolve the type of this template.
  #
  # @return [Symbol]
  def type
    raise "Please implement #type on #{self.class.inspect}."
  end

  # @abstract
  # Returns the tokens of this templates. Tokens should include either {Literal} or {Expression}.
  #
  # @return [Array<URITemplate::Token>]
  def tokens
    raise "Please implement #tokens on #{self.class.inspect}."
  end

  # Returns an array containing all variables. Repeated variables are ignored. The concrete order of the variables may change.
  # @example
  #   URITemplate.new('{foo}{bar}{baz}').variables #=> ['foo','bar','baz']
  #   URITemplate.new('{a}{c}{a}{b}').variables #=> ['a','c','b']
  #
  # @return [Array<String>]
  def variables
    @variables ||= tokens.map(&:variables).flatten.uniq.freeze
  end

  # Returns the number of static characters in this template.
  # This method is useful for routing, since it's often pointful to use the url with fewer variable characters.
  # For example 'static' and 'sta\\{var\\}' both match 'static', but in most cases 'static' should be prefered over 'sta\\{var\\}' since it's more specific.
  #
  # @example
  #   URITemplate.new('/xy/').static_characters #=> 4
  #   URITemplate.new('{foo}').static_characters #=> 0
  #   URITemplate.new('a{foo}b').static_characters #=> 2
  #
  # @return Numeric
  def static_characters
    @static_characters ||= tokens.select(&:literal?).map{|t| t.string.size }.inject(0,:+)
  end

  # Returns whether this uri-template includes a host name
  #
  # This method is usefull to check wheter this template will generate 
  # or match a uri with a host.
  #
  # @see #scheme?
  #
  # @example
  #   URITemplate.new('/foo').host? #=> false
  #   URITemplate.new('//example.com/foo').host? #=> true
  #   URITemplate.new('//{host}/foo').host? #=> true
  #   URITemplate.new('http://example.com/foo').host? #=> true
  #   URITemplate.new('{scheme}://example.com/foo').host? #=> true
  #
  def host?
    return scheme_and_host[1]
  end

  # Returns whether this uri-template includes a scheme
  #
  # This method is usefull to check wheter this template will generate 
  # or match a uri with a scheme.
  # 
  # @see #host?
  #
  # @example
  #   URITemplate.new('/foo').scheme? #=> false
  #   URITemplate.new('//example.com/foo').scheme? #=> false
  #   URITemplate.new('http://example.com/foo').scheme? #=> true
  #   URITemplate.new('{scheme}://example.com/foo').scheme? #=> true
  #
  def scheme?
    return scheme_and_host[0]
  end

  # Returns the pattern for this template.
  #
  # @return String
  def pattern
    @pattern ||= tokens.map(&:to_s).join
  end

  alias to_s pattern

  # Compares two template patterns.
  def eq(other)
    return self.pattern == other.pattern
  end

  coerce_first_arg :eq

  alias == eq

  # Tries to concatenate two templates, as if they were path segments.
  # Removes double slashes or insert one if they are missing.
  #
  # @example
  #   tpl = URITemplate::RFC6570.new('/xy/')
  #   (tpl / '/z/' ).pattern #=> '/xy/z/'
  #   (tpl / 'z/' ).pattern #=> '/xy/z/'
  #   (tpl / '{/z}' ).pattern #=> '/xy{/z}'
  #   (tpl / 'a' / 'b' ).pattern #=> '/xy/a/b'
  #
  # @param other [URITemplate, String, ...]
  # @return URITemplate
  def path_concat(other)
    if other.host? or other.scheme?
      raise ArgumentError, "Expected to receive a relative template but got an absoulte one: #{other.inspect}. If you think this is a bug, please report it."
    end

    return self if other.tokens.none?
    return other if self.tokens.none?

    tail = self.tokens.last
    head = other.tokens.first

    if tail.ends_with_slash?
      if head.starts_with_slash?
        return self.class.new( remove_double_slash(self.tokens, other.tokens).join )
      end
    elsif !head.starts_with_slash?
      return self.class.new( (self.tokens + ['/'] + other.tokens).join)
    end
    return self.class.new( (self.tokens + other.tokens).join )
  end

  coerce_first_arg :path_concat

  alias / path_concat

  # Concatenate two template with conversion.
  #
  # @example
  #   tpl = URITemplate::RFC6570.new('foo')
  #   (tpl + '{bar}' ).pattern #=> 'foo{bar}'
  #
  # @param other [URITemplate, String, ...]
  # @return URITemplate
  def concat(other)
    if other.host? or other.scheme?
      raise ArgumentError, "Expected to receive a relative template but got an absoulte one: #{other.inspect}. If you think this is a bug, please report it."
    end

    return self if other.tokens.none?
    return other if self.tokens.none?
    return self.class.new( self.to_s + other.to_s )
  end

  coerce_first_arg :concat

  alias + concat
  alias >> concat

  # @api private
  def remove_double_slash( first_tokens, second_tokens )
    if first_tokens.last.literal?
      return first_tokens[0..-2] + [ first_tokens.last.to_s[0..-2] ] + second_tokens
    elsif second_tokens.first.literal?
      return first_tokens + [ second_tokens.first.to_s[1..-1] ] + second_tokens[1..-1]
    else
      raise ArgumentError, "Cannot remove double slashes from #{first_tokens.inspect} and #{second_tokens.inspect}."
    end
  end

  private :remove_double_slash

  # @api private
  def scheme_and_host
    return @scheme_and_host if @scheme_and_host
    read_chars = ""
    @scheme_and_host = [false,false]
    tokens.each do |token|
      if token.expression?
        read_chars << "x"
        if token.scheme?
          read_chars << ':'
        end
        if token.host?
          read_chars << '//'
        end
        read_chars << "x"
      elsif token.literal?
        read_chars << token.string
      end
      if read_chars =~ SCHEME_REGEX
        @scheme_and_host = [true, true]
        break
      elsif read_chars =~ HOST_REGEX
        @scheme_and_host[1] = true
        break
      elsif read_chars =~ /(^|[^:\/])\/(?!\/)/
        break
      end
    end
    return @scheme_and_host
  end

  private :scheme_and_host

  alias absolute? host?

  # Opposite of {#absolute?}
  def relative?
    !absolute?
  end

end
