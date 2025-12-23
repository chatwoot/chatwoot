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

require 'strscan'
require 'set'
require 'forwardable'

require 'uri_template'
require 'uri_template/utils'

# A uri template which should comply with the rfc 6570 ( http://tools.ietf.org/html/rfc6570 ).
# @note
#   Most specs and examples refer to this class directly, because they are acutally refering to this specific implementation. If you just want uri templates, you should rather use the methods on {URITemplate} to create templates since they will select an implementation.
class URITemplate::RFC6570

  TYPE = :rfc6570

  include URITemplate
  extend Forwardable

  # @private
  module Utils

    include URITemplate::Utils

    # Returns true iff the value is `defined` [RFC6570 Section 2.3](http://tools.ietf.org/html/rfc6570#section-2.3)
    # 
    # The only undefined things are:
    # - nil
    # - arrays containing no defined value
    # - associative arrays/hashes containing no defined value
    #
    # Things that are always defined:
    # - Strings, independent of the length
    def def?( value )
      case( value )
      when nil  then
        false
      when Hash then
        value.any?{|_, v| !v.nil? }
      when Array then
        if value.none?
          false
        elsif value[0].kind_of?(Array)
          value.any?{|_,v| !v.nil? }
        else
          value.any?{|v| !v.nil? }
        end
      else
        true
      end
    end

    extend self

  end

  # :nocov:
  if Utils.use_unicode?
    # @private
    #                           \/ - unicode ctrl-chars
    LITERAL = /([^"'%<>\\^`{|}\u0000-\u001F\u007F-\u009F\s]|%[0-9a-fA-F]{2})+/u
  else
    # @private
    LITERAL = Regexp.compile('([^"\'%<>\\\\^`{|}\x00-\x1F\x7F-\x9F\s]|%[0-9a-fA-F]{2})+',Utils::KCODE_UTF8)
  end
  # :nocov:

  # @private
  CHARACTER_CLASSES = {

    :unreserved => {
      :class => '(?:[A-Za-z0-9\-\._]|%[0-9a-fA-F]{2})',
      :class_with_comma => '(?:[A-Za-z0-9\-\._,]|%[0-9a-fA-F]{2})',
      :class_without_comma => '(?:[A-Za-z0-9\-\._]|%[0-9a-fA-F]{2})',
      :grabs_comma => false
    },
    :unreserved_reserved_pct => {
      :class => '(?:[A-Za-z0-9\-\._:\/?#\[\]@!\$%\'\(\)*+,;=]|%[0-9a-fA-F]{2})',
      :class_with_comma => '(?:[A-Za-z0-9\-\._:\/?#\[\]@!\$%\'\(\)*+,;=]|%[0-9a-fA-F]{2})',
      :class_without_comma => '(?:[A-Za-z0-9\-\._:\/?#\[\]@!\$%\'\(\)*+;=]|%[0-9a-fA-F]{2})',
      :grabs_comma => true
    },

    :varname => {
      :class => '(?:[A-Za-z0-9\-\._]|%[0-9a-fA-F]{2})+',
      :class_name => 'c_vn_'
    }

  }

  # Specifies that no processing should be done upon extraction.
  # @see #extract
  NO_PROCESSING = []

  # Specifies that the extracted values should be processed.
  # @see #extract
  CONVERT_VALUES = [:convert_values]

  # Specifies that the extracted variable list should be processed.
  # @see #extract
  CONVERT_RESULT = [:convert_result]

  # Default processing. Means: convert values and the list itself.
  # @see #extract
  DEFAULT_PROCESSING = CONVERT_VALUES + CONVERT_RESULT

  # @private
  VAR = Regexp.compile(Utils.compact_regexp(<<'__REGEXP__'), Utils::KCODE_UTF8)
(
  (?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2})
  (?:\.?
    (?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2})
  )*
)
(?:(\*)|:([1-9]\d{0,3})|)
__REGEXP__

  # @private
  EXPRESSION = Regexp.compile(Utils.compact_regexp(<<'__REGEXP__'), Utils::KCODE_UTF8)
\{
  ([+#\./;?&]?)
  (
    (?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2})
    (?:\.?(?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2}))*
    (?:\*|:[1-9]\d{0,3}|)
    (?:
      ,
      (?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2})
      (?:\.?(?:[a-zA-Z0-9_]|%[0-9a-fA-F]{2}))*
      (?:\*|:[1-9]\d{0,3}|)
    )*
  )
\}
__REGEXP__

  # @private
  URI = Regexp.compile(<<__REGEXP__.strip, Utils::KCODE_UTF8)
\\A(#{LITERAL.source}|#{EXPRESSION.source})*\\z
__REGEXP__

  # @private
  class Token
  end

  # @private
  class Literal < Token

    include URITemplate::Literal

    def initialize(string)
      @string = string
    end

    def level
      1
    end

    def to_r_source(*_)
      Regexp.escape(@string)
    end

    def to_s
      @string
    end

  end

  # This error is raised when an invalid pattern was given.
  class Invalid < StandardError

    include URITemplate::Invalid

    attr_reader :pattern, :position

    def initialize(source, position)
      @pattern = source
      @position = position
      super("Invalid expression found in #{source.inspect} at #{position}: '#{source[position..-1]}'")
    end

  end

  # @private
  class Tokenizer

    include Enumerable

    attr_reader :source

    def initialize(source, ops)
      @source = source
      @operators = ops
    end

    def each
      scanner = StringScanner.new(@source)
      until scanner.eos?
        expression = scanner.scan(EXPRESSION)
        if expression
          vars = scanner[2].split(',').map{|name|
            match = VAR.match(name)
            # 1 = varname
            # 2 = explode
            # 3 = length
            [ match[1], match[2] == '*', match[3].to_i ]
          }
          yield @operators[scanner[1]].new(vars)
        else
          literal = scanner.scan(LITERAL)
          if literal
            yield(Literal.new(literal))
          else
            raise Invalid.new(@source,scanner.pos)
          end
        end
      end
    end

  end

  # The class methods for all rfc6570 templates.
  module ClassMethods

    # Tries to convert the given param in to a instance of {RFC6570}
    # It basically passes thru instances of that class, parses strings and return nil on everything else.
    #
    # @example
    #   URITemplate::RFC6570.try_convert( Object.new ) #=> nil
    #   tpl = URITemplate::RFC6570.new('{foo}')
    #   URITemplate::RFC6570.try_convert( tpl ) #=> tpl
    #   URITemplate::RFC6570.try_convert('{foo}') #=> tpl
    #   URITemplate::RFC6570.try_convert(URITemplate.new(:colon, ':foo')) #=> tpl
    #   # This pattern is invalid, so it wont be parsed:
    #   URITemplate::RFC6570.try_convert('{foo') #=> nil
    #
    def try_convert(x)
      if x.class == self
        return x
      elsif x.kind_of? String and valid? x
        return new(x)
      elsif x.kind_of? URITemplate::Colon
        return nil if x.tokens.any?{|tk| tk.kind_of? URITemplate::Colon::Token::Splat }
        return new( x.tokens.map{|tk|
          if tk.literal?
            Literal.new(tk.string)
          else
            Expression.new([[tk.variables.first, false, 0]])
          end
        })
      else
        return nil
      end
    end

    # Tests whether a given pattern is a valid template pattern.
    # @example
    #   URITemplate::RFC6570.valid? 'foo' #=> true
    #   URITemplate::RFC6570.valid? '{foo}' #=> true
    #   URITemplate::RFC6570.valid? '{foo' #=> false
    def valid?(pattern)
      URI === pattern
    end

  end

  extend ClassMethods

  attr_reader :options

  # @param pattern_or_tokens [String,Array] either a pattern as String or an Array of tokens
  # @param options [Hash] some options
  # @option :lazy [true,false] If true the pattern will be parsed on first access, this also means that syntax errors will not be detected unless accessed.
  def initialize(pattern_or_tokens,options={})
    @options = options.dup.freeze
    if pattern_or_tokens.kind_of? String
      @pattern = pattern_or_tokens.dup
      @pattern.freeze
      unless @options[:lazy]
        self.tokens
      end
    elsif pattern_or_tokens.kind_of? Array
      @tokens = pattern_or_tokens.dup
      @tokens.freeze
    else
      raise ArgumentError, "Expected to receive a pattern string, but got #{pattern_or_tokens.inspect}"
    end
  end

  # @method expand(variables = {})
  # Expands the template with the given variables.
  # The expansion should be compatible to uritemplate spec rfc 6570 ( http://tools.ietf.org/html/rfc6570 ).
  # @note
  #   All keys of the supplied hash should be strings as anything else won't be recognised.
  # @note
  #   There are neither default values for variables nor will anything be raised if a variable is missing. Please read the spec if you want to know how undefined variables are handled.
  # @example
  #   URITemplate::RFC6570.new('{foo}').expand('foo'=>'bar') #=> 'bar'
  #   URITemplate::RFC6570.new('{?args*}').expand('args'=>{'key'=>'value'}) #=> '?key=value'
  #   URITemplate::RFC6570.new('{undef}').expand() #=> ''
  #
  # @param variables [Hash, Array]
  # @return String

  # @method expand_partial(variables = {})
  # Works like expand but keeps missing variables in place.
  # @example
  #   URITemplate::RFC6570.new('{foo}').expand_partial('foo'=>'bar') #=> URITemplate::RFC6570.new('bar{foo}')
  #   URITemplate::RFC6570.new('{undef}').expand_partial() #=> URITemplate::RFC6570.new('{undef}')
  #
  # @param variables [Hash,Array]
  # @return URITemplate

  # Compiles this template into a regular expression which can be used to test whether a given uri matches this template. This template is also used for {#===}.
  #
  # @example
  #   tpl = URITemplate::RFC6570.new('/foo/{bar}/')
  #   regex = tpl.to_r
  #   regex === '/foo/baz/' #=> true
  #   regex === '/foz/baz/' #=> false
  # 
  # @return Regexp
  def to_r
    @regexp ||= begin
      source = tokens.map(&:to_r_source)
      source.unshift('\A')
      source.push('\z')
      Regexp.new( source.join, Utils::KCODE_UTF8)
    end
  end

  # Extracts variables from a uri ( given as string ) or an instance of MatchData ( which was matched by the regexp of this template.
  # The actual result depends on the value of post_processing.
  # This argument specifies whether pair arrays should be converted to hashes.
  # 
  # @example Default Processing
  #   URITemplate::RFC6570.new('{var}').extract('value') #=> {'var'=>'value'}
  #   URITemplate::RFC6570.new('{&args*}').extract('&a=1&b=2') #=> {'args'=>{'a'=>'1','b'=>'2'}}
  #   URITemplate::RFC6570.new('{&arg,arg}').extract('&arg=1&arg=2') #=> {'arg'=>'2'}
  #
  # @example No Processing
  #   URITemplate::RFC6570.new('{var}').extract('value', URITemplate::RFC6570::NO_PROCESSING) #=> [['var','value']]
  #   URITemplate::RFC6570.new('{&args*}').extract('&a=1&b=2', URITemplate::RFC6570::NO_PROCESSING) #=> [['args',[['a','1'],['b','2']]]]
  #   URITemplate::RFC6570.new('{&arg,arg}').extract('&arg=1&arg=2', URITemplate::RFC6570::NO_PROCESSING) #=> [['arg','1'],['arg','2']]
  #
  # @raise Encoding::InvalidByteSequenceError when the given uri was not properly encoded.
  # @raise Encoding::UndefinedConversionError when the given uri could not be converted to utf-8.
  # @raise Encoding::CompatibilityError when the given uri could not be converted to utf-8.
  #
  # @param uri_or_match [String,MatchData] Uri_or_MatchData A uri or a matchdata from which the variables should be extracted.
  # @param post_processing [Array] Processing Specifies which processing should be done.
  # 
  # @note
  #   Don't expect that an extraction can fully recover the expanded variables. Extract rather generates a variable list which should expand to the uri from which it were extracted. In general the following equation should hold true:
  #     a_tpl.expand( a_tpl.extract( an_uri ) ) == an_uri
  #
  # @example Extraction cruces
  #   two_lists = URITemplate::RFC6570.new('{listA*,listB*}')
  #   uri = two_lists.expand('listA'=>[1,2],'listB'=>[3,4]) #=> "1,2,3,4"
  #   variables = two_lists.extract( uri ) #=> {'listA'=>["1","2","3"],'listB'=>["4"]}
  #   # However, like said in the note:
  #   two_lists.expand( variables ) == uri #=> true
  #
  # @note
  #   The current implementation drops duplicated variables instead of checking them.
  #   
  def extract(uri_or_match, post_processing = DEFAULT_PROCESSING )
    if uri_or_match.kind_of? String
      m = self.to_r.match(uri_or_match)
    elsif uri_or_match.kind_of?(MatchData)
      if uri_or_match.respond_to?(:regexp) and uri_or_match.regexp != self.to_r
        raise ArgumentError, "Trying to extract variables from MatchData which was not generated by this template."
      end
      m = uri_or_match
    elsif uri_or_match.nil?
      return nil
    else
      raise ArgumentError, "Expected to receive a String or a MatchData, but got #{uri_or_match.inspect}."
    end
    if m.nil?
      return nil
    else
      result = extract_matchdata(m, post_processing)
      if block_given?
        return yield result
      end
      return result
    end
  end

  # Extracts variables without any proccessing.
  # This is equivalent to {#extract} with options {NO_PROCESSING}.
  # @see #extract
  def extract_simple(uri_or_match)
    extract( uri_or_match, NO_PROCESSING )
  end

  # @method ===(uri)
  # Alias for to_r.=== . Tests whether this template matches a given uri.
  # @return TrueClass, FalseClass
  def_delegators :to_r, :===

  # @method match(uri)
  # Alias for to_r.match . Matches this template against the given uri.
  # @yield MatchData
  # @return MatchData, Object 
  def_delegators :to_r, :match

  # The type of this template.
  #
  # @example
  #   tpl1 = URITemplate::RFC6570.new('/foo')
  #   tpl2 = URITemplate.new( tpl1.pattern, tpl1.type )
  #   tpl1 == tpl2 #=> true
  #
  # @see {URITemplate#type}
  def type
    self.class::TYPE
  end

  # Returns the level of this template according to the rfc 6570 ( http://tools.ietf.org/html/rfc6570#section-1.2 ). Higher level means higher complexity.
  # Basically this is defined as:
  # 
  # * Level 1: no operators, one variable per expansion, no variable modifiers
  # * Level 2: '+' and '#' operators, one variable per expansion, no variable modifiers
  # * Level 3: all operators, multiple variables per expansion, no variable modifiers
  # * Level 4: all operators, multiple variables per expansion, all variable modifiers
  #
  # @example
  #   URITemplate::RFC6570.new('/foo/').level #=> 1
  #   URITemplate::RFC6570.new('/foo{bar}').level #=> 1
  #   URITemplate::RFC6570.new('/foo{#bar}').level #=> 2
  #   URITemplate::RFC6570.new('/foo{.bar}').level #=> 3
  #   URITemplate::RFC6570.new('/foo{bar,baz}').level #=> 3
  #   URITemplate::RFC6570.new('/foo{bar:20}').level #=> 4
  #   URITemplate::RFC6570.new('/foo{bar*}').level #=> 4
  #
  # Templates of lower levels might be convertible to other formats while templates of higher levels might be incompatible. Level 1 for example should be convertible to any other format since it just contains simple expansions.
  #
  def level
    tokens.map(&:level).max
  end

  # Returns an array containing a the template tokens.
  def tokens
    @tokens ||= tokenize!
  end

protected
  # @private
  def tokenize!
    self.class::Tokenizer.new(pattern, self.class::OPERATORS).to_a
  end

  # @private
  def extract_matchdata(matchdata, post_processing)
    bc = 1
    vars = []
    tokens.each{|part|
      next if part.literal?
      i = 0
      pa = part.arity
      while i < pa
        vars.push( *part.extract(i, matchdata[bc]) )
        bc += 1
        i += 1
      end
    }
    if post_processing.include? :convert_result
      if post_processing.include? :convert_values
        return Hash[ vars.map!{|k,v| [k,Utils.pair_array_to_hash(v)] } ]
      else
        return Hash[vars]
      end
    else
      if post_processing.include? :convert_values
        return vars.collect{|k,v| [k,Utils.pair_array_to_hash(v)] }
      else
        return vars
      end
    end
  end

end

require 'uri_template/rfc6570/regex_builder.rb'
require 'uri_template/rfc6570/expression.rb'
