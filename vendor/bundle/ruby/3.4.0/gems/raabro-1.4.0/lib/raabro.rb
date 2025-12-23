# frozen_string_literal: true

module Raabro

  VERSION = '1.4.0'

  class Input

    attr_accessor :string, :offset
    attr_reader :options

    def initialize(string, offset=0, options={})

      @string = string
      @offset = offset.is_a?(Hash) ? 0 : offset
      @options = offset.is_a?(Hash) ? offset : options
    end

    def match(str_or_regex)

      if str_or_regex.is_a?(Regexp)
        m = @string[@offset..-1].match(str_or_regex)
        m && (m.offset(0).first == 0) ? m[0].length : false
      else # String or whatever responds to #to_s
        s = str_or_regex.to_s
        l = s.length
        @string[@offset, l] == s ? l : false
      end
    end

    def tring(l=-1)

      l < 0 ? @string[@offset..l] : @string[@offset, l]
    end

    def at(i)

      @string[i, 1]
    end
  end

  class Tree

    attr_accessor :name, :input
    attr_accessor :result # ((-1 error,)) 0 nomatch, 1 success
    attr_accessor :offset, :length
    attr_accessor :parter, :children

    def initialize(name, parter, input)

      @result = 0
      @name = name
      @parter = parter
      @input = input
      @offset = input.offset
      @length = 0
      @children = []
    end

    def c0; @children[0]; end
    def c1; @children[1]; end
    def c2; @children[2]; end
    def c3; @children[3]; end
    def c4; @children[4]; end
    def clast; @children.last; end

    def empty?

      @result == 1 && @length == 0
    end

    def successful_children

      @children.select { |c| c.result == 1 }
    end

    def prune!

      @children = successful_children
    end

    def string; @input.string[@offset, @length]; end
    def strinp; string.strip; end
    alias strim strinp
    def nonstring(l=7); @input.string[@offset, l]; end

    def stringd; string.downcase; end
    alias strind stringd
    def stringpd; strinp.downcase; end
    alias strinpd stringpd

    def symbol; strinp.to_sym; end
    def symbold; symbol.downcase; end
    alias symbod symbold

    def lookup(name=nil)

      name = name ? name.to_s : nil

      return self if @name && name == nil
      return self if @name.to_s == name
      sublookup(name)
    end

    def sublookup(name=nil)

      @children.each { |c| if n = c.lookup(name); return n; end }

      nil
    end

    def gather(name=nil, acc=[])

      name = name ? name.to_s : nil

      if (@name && name == nil) || (@name.to_s == name)
        acc << self
      else
        subgather(name, acc)
      end

      acc
    end

    def subgather(name=nil, acc=[])

      @children.each { |c| c.gather(name, acc) }

      acc
    end

    def to_a(opts={})

      opts = Array(opts).inject({}) { |h, e| h[e] = true; h } \
        unless opts.is_a?(Hash)

      cn =
        if opts[:leaves] && (@result == 1) && @children.empty?
          string
        elsif opts[:children] != false
          @children.collect { |e| e.to_a(opts) }
        else
          @children.length
        end

      [ @name, @result, @offset, @length, @note, @parter, cn ]
    end

    def to_s(depth=0, io=StringIO.new)

      io.print "\n" if depth > 0
      io.print '  ' * depth
      io.print "#{@result} #{@name.inspect} #{@offset},#{@length}"
      io.print result == 1 && children.size == 0 ? ' ' + string.inspect : ''

      @children.each { |c| c.to_s(depth + 1, io) }

      depth == 0 ? io.string : nil
    end

    def odd_children

      cs = []; @children.each_with_index { |c, i| cs << c if i.odd? }; cs
    end

    def even_children

      cs = []; @children.each_with_index { |c, i| cs << c if i.even? }; cs
    end

    def extract_error

#Raabro.pp(self, colors: true)
      err_tree, stack = lookup_error || lookup_all_error

      line, column = line_and_column(err_tree.offset)

      err_message =
        if stack
          path = stack
           .compact.reverse.take(3).reverse
           .collect(&:inspect).join('/')
          "parsing failed .../#{path}"
        else
          'parsing failed, not all input was consumed'
        end
      visual =
        visual(line, column)

      [ line, column, err_tree.offset, err_message, visual ]
    end

    def lookup_error(stack=[])

#print 'le(): '; Raabro.pp(self, colors: true)
      return nil if @result != 0
      return [ self, stack ] if @children.empty?
      @children.each { |c|
        es = c.lookup_error(stack.dup.push(self.name))
        return es if es }
      nil
    end

    # Not "lookup all errors" but "lookup all error", in other
    # words lookup the point up until which the parser stopped (not
    # consuming all the input)
    #
    def lookup_all_error

#print "lae(): "; Raabro.pp(self, colors: true)
      @children.each { |c| return [ c, nil ] if c.result == 0 }
      @children.reverse.each { |c| es = c.lookup_all_error; return es if es }
      nil
    end

    def line_and_column(offset)

      line = 1
      column = 0

      (0..offset).each do |off|

        column += 1
        next unless @input.at(off) == "\n"

        line += 1
        column = 0
      end

      [ line, column ]
    end

    def visual(line, column)

      @input.string.split("\n")[line - 1] + "\n" +
      ' ' * (column - 1) + '^---'
    end
  end

  module ModuleMethods

    def _match(name, input, parter, regex_or_string)

      r = Raabro::Tree.new(name, parter, input)

      if l = input.match(regex_or_string)
        r.result = 1
        r.length = l
        input.offset += l
      end

      r
    end

    def str(name, input, string)

      _match(name, input, :str, string)
    end

    def rex(name, input, regex_or_string)

      _match(name, input, :rex, Regexp.new(regex_or_string))
    end

    def _quantify(parser)

      return nil if parser.is_a?(Symbol) && respond_to?(parser)
        # so that :plus and co can be overriden

      case parser
      when '?', :q, :qmark then [ 0, 1 ]
      when '*', :s, :star then [ 0, 0 ]
      when '+', :p, :plus then [ 1, 0 ]
      when '!' then :bang
      else nil
      end
    end

    def _narrow(parser)

      fail ArgumentError.new("lone quantifier #{parser}") if _quantify(parser)

      method(parser.to_sym)
    end

    def _parse(parser, input)

      #p [ caller.length, parser, input.tring ]
      #r = _narrow(parser).call(input)
      #p [ caller.length, parser, input.tring, r.to_a(children: false) ]
      #r
      _narrow(parser).call(input)
    end

    def seq(name, input, *parsers)

      r = ::Raabro::Tree.new(name, :seq, input)

      start = input.offset
      c = nil

      loop do

        pa = parsers.shift
        break unless pa

        if parsers.first == '!'
          parsers.shift
          c = nott(nil, input, pa)
          r.children << c
        elsif q = _quantify(parsers.first)
          parsers.shift
          c = rep(nil, input, pa, *q)
          r.children.concat(c.children)
        else
          c = _parse(pa, input)
          r.children << c
        end

        break if c.result != 1
      end

      if c && c.result == 1
        r.result = 1
        r.length = input.offset - start
      else
        input.offset = start
      end

      r
    end

    def alt(name, input, *parsers)

      greedy =
        if parsers.last == true || parsers.last == false
          parsers.pop
        else
          false
        end

      r = ::Raabro::Tree.new(name, greedy ? :altg : :alt, input)

      start = input.offset
      c = nil

      parsers.each do |pa|

        cc = _parse(pa, input)
        r.children << cc

        input.offset = start

        if greedy
          if cc.result == 1 && cc.length >= (c ? c.length : -1)
            c.result = 0 if c
            c = cc
          else
            cc.result = 0
          end
        else
          c = cc
          break if c.result == 1
        end
      end

      if c && c.result == 1
        r.result = 1
        r.length = c.length
        input.offset = start + r.length
      end

      r.prune! if input.options[:prune]

      r
    end

    def altg(name, input, *parsers)

      alt(name, input, *parsers, true)
    end

    def rep(name, input, parser, min, max=0)

      min = 0 if min == nil || min < 0
      max = nil if max.nil? || max < 1

      r = ::Raabro::Tree.new(name, :rep, input)
      start = input.offset
      count = 0

      loop do
        c = _parse(parser, input)
        r.children << c
        break if c.result != 1
        count += 1
        break if c.length < 1
        break if max && count == max
      end

      if count >= min && (max == nil || count <= max)
        r.result = 1
        r.length = input.offset - start
      else
        input.offset = start
      end

      r.prune! if input.options[:prune]

      r
    end

    def ren(name, input, parser)

      r = _parse(parser, input)
      r.name = name

      r
    end
    alias rename ren

    def nott(name, input, parser)

      start = input.offset

      r = ::Raabro::Tree.new(name, :nott, input)
      c = _parse(parser, input)
      r.children << c

      r.length = 0
      r.result = c.result == 1 ? 0 : 1

      input.offset = start

      r
    end

    def all(name, input, parser)

      start = input.offset
      length = input.string.length - input.offset

      r = ::Raabro::Tree.new(name, :all, input)
      c = _parse(parser, input)
      r.children << c

      if c.length < length
        input.offset = start
      else
        r.result = 1
        r.length = c.length
      end

      r
    end

    def eseq(name, input, startpa, eltpa, seppa=nil, endpa=nil)

      jseq = false

      if seppa.nil? && endpa.nil?
        jseq = true
        seppa = eltpa; eltpa = startpa; startpa = nil
      end

      start = input.offset
      r = ::Raabro::Tree.new(name, jseq ? :jseq : :eseq, input)
      r.result = 1
      c = nil

      if startpa
        c = _parse(startpa, input)
        r.children << c
        r.result = 0 if c.result != 1
      end

      if r.result == 1

        on_elt = false
        count = 0
        empty_stack = 0

        loop do

          on_elt = ! on_elt

          cr = _parse(on_elt ? eltpa : seppa, input)

          empty_stack = cr.empty? ? empty_stack + 1 : 0
          cr.result = 0 if empty_stack > 1
            #
            # prevent "no progress"

          r.children.push(cr)

          if cr.result != 1
            if on_elt && count > 0
              lsep = r.children[-2]
              lsep.result = 0
              input.offset = lsep.offset
            end
            break
          end

          count += 1
        end

        r.result = 0 if jseq && count < 1
      end

      if r.result == 1 && endpa
        c = _parse(endpa, input)
        r.children << c
        r.result = 0 if c.result != 1
      end

      if r.result == 1
        r.length = input.offset - start
      else
        input.offset = start
      end

      r.prune! if input.options[:prune]

      r
    end
    alias jseq eseq

    attr_accessor :last

    def method_added(name)

      m = method(name)
      return unless m.arity == 1
      return unless m.parameters[0][1] == :i || m.parameters[0][1] == :input

      @last = name.to_sym
    end

    def parse(input, opts={})

      d = opts[:debug].to_i
      opts[:rewrite] = false if d > 0
      opts[:all] = false if d > 1
      opts[:prune] = false if d > 2

      opts[:prune] = true unless opts.has_key?(:prune)

      root = self.respond_to?(:root) ? :root : @last

      t =
        if opts[:all] == false
          _parse(root, Raabro::Input.new(input, opts))
        else
          all(nil, Raabro::Input.new(input, opts), root)
        end

      return reparse_for_error(input, opts, t) if opts[:error] && t.result != 1
      return nil if opts[:prune] != false && t.result != 1

      t = t.children.first if t.parter == :all

      return rewrite(t) if opts[:rewrite] != false

      t
    end

    def reparse_for_error(input, opts, t)

      t =
        opts[:prune] == false ?
        t :
        parse(input, opts.merge(error: false, rewrite: false, prune: false))
#Raabro.pp(t, colours: true)

      t.extract_error
    end

    def rewrite_(tree)

      t = tree.lookup(nil)

      t ? rewrite(t) : nil
    end

    def rewrite(tree)

      return !! methods.find { |m| m.to_s.start_with?('rewrite_') } if tree == 0
        # return true when "rewrite_xxx" methods seem to have been provided

      send("rewrite_#{tree.name}", tree)
    end

    def make_includable

      def self.included(target)

        target.instance_eval do
          extend ::Raabro::ModuleMethods
          extend self
        end
      end
    end
  end
  extend ModuleMethods

  make_includable

    # Black       0;30     Dark Gray     1;30
    # Blue        0;34     Light Blue    1;34
    # Green       0;32     Light Green   1;32
    # Cyan        0;36     Light Cyan    1;36
    # Red         0;31     Light Red     1;31
    # Purple      0;35     Light Purple  1;35
    # Brown       0;33     Yellow        1;33
    # Light Gray  0;37     White         1;37

  def self.pp(tree, depth=0, opts={})

    fail ArgumentError.new(
      'tree is not an instance of Raabro::Tree'
    ) unless tree.is_a?(Raabro::Tree)

    depth, opts = 0, depth if depth.is_a?(Hash)

    _rs, _dg, _gn, _yl, _bl, _lg =
      (opts[:colors] || opts[:colours] || $stdout.tty?) ?
      [ "[0;0m", "[1;30m", "[0;32m", "[1;33m", "[0;34m", "[0;37m" ] :
      [ '', '', '', '', '', '' ]

    lc = tree.result == 1 ? _gn : _dg
    nc = tree.result == 1 ? _bl : _lg
    nc = lc if tree.name == nil
    sc = tree.result == 1 ? _yl : _dg

    str =
      if tree.children.size == 0
        " #{sc}#{tree.string.length == 0 ?
        "#{_dg} >#{tree.nonstring(14).inspect[1..-2]}<" :
        tree.string.inspect}"
      else
        ''
      end

    print "#{_dg}t---\n" if depth == 0

    #print "#{'  ' * depth}"
    depth.times do |i|
      pipe = i % 3 == 0 ? ': ' : '| '
      print i.even? ? "#{_dg}#{pipe} " : '  '
    end

    print "#{lc}#{tree.result}"
    print " #{nc}#{tree.name.inspect} #{lc}#{tree.offset},#{tree.length}"
    print str
    print "#{_rs}\n"

    tree.children.each { |c| self.pp(c, depth + 1, opts) }

    if depth == 0
      print _dg
      print "input ln: #{tree.input.string.length}, tree ln: #{tree.length} "
      print "---t\n"
      print _rs
    end
  end
end

