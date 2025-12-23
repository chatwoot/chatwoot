$TESTING ||= false # unless defined $TESTING

##
# Sexps are the basic storage mechanism of SexpProcessor.  Sexps have
# a +type+ (to be renamed +node_type+) which is the first element of
# the Sexp. The type is used by SexpProcessor to determine whom to
# dispatch the Sexp to for processing.

class Sexp < Array # ZenTest FULL
  ##
  # A setter for the line this sexp was found on. Usually set by ruby_parser.

  attr_writer :line

  ##
  # Set the maximum line number for this sexp. Often set by ruby_parser.

  attr_writer :line_max

  ##
  # Accessors for the file. Usually set by ruby_parser.

  attr_accessor :file

  ##
  # Optional comments above/aside this sexp. Usually set by ruby_parser.

  attr_accessor :comments

  @@array_types = [ :array, :args ] # TODO: remove

  ##
  # Create a new Sexp containing +args+.

  def initialize *args
    super(args)
  end

  alias _concat concat

  ##
  # Creates a new Sexp from Array +a+.

  def self.from_array a
    ary = Array === a ? a : [a]

    self.new._concat(ary.map { |x|
               case x
               when Sexp
                 x
               when Array
                 self.from_array(x)
               else
                 x
               end
             })
  end

  ##
  # Creates a new sexp with the new contents of +body+, but with the
  # same +file+, +line+, and +comment+ as self.

  def new(*body)
    r = self.class.new._concat(body) # ensures a sexp from map
    r.file     = self.file     if self.file
    r.line     = self.line     if self.line
    r.line_max = self.line_max if defined?(@line_max)
    r.comments = self.comments if self.comments
    r
  end

  def map &blk # :nodoc:
    self.new._concat(super(&blk)) # ensures a sexp from map
  end

  def == obj # :nodoc:
    obj.class == self.class and super # only because of a bug in ruby
  end

  def eql? o
    self.class == o.class && super
  end

  def hash
    @hash ||= [self.class, *self].hash
  end

  ##
  # Returns true if the node_type is +array+ or +args+.
  #
  # REFACTOR: to TypedSexp - we only care when we have units.

  def array_type?
    warn "DEPRECATED: please file an issue if you actually use this. from #{caller.first}"
    type = self.sexp_type
    @@array_types.include? type
  end

  def compact # :nodoc:
    self.delete_if(&:nil?)
  end

  ##
  # Recursively enumerates the sexp yielding to +block+ for every sub-Sexp.
  #
  # Returning :skip will stop traversing that subtree:
  #
  #   sexp.deep_each do |s|
  #     next :skip if s.sexp_type == :if
  #     # ...
  #   end

  def deep_each &block
    return enum_for(:deep_each) unless block_given?

    self.each_sexp do |sexp|
      next if block[sexp] == :skip
      sexp.deep_each(&block)
    end
  end

  ##
  # Return the maximum depth of the sexp. One-based.

  def depth
    1 + (each_sexp.map(&:depth).max || 0)
  end

  ##
  # Enumeratates the sexp yielding to +b+ when the node_type == +t+.

  def each_of_type t, &b
    return enum_for(:each_of_type, t) unless block_given?

    each_sexp do | sexp |
      sexp.each_of_type(t, &b)
      yield sexp if sexp.sexp_type == t
    end
  end

  ##
  # Enumerates all sub-sexps skipping non-Sexp elements.

  def each_sexp
    return enum_for(:each_sexp) unless block_given?

    self.each do |sexp|
      next unless Sexp === sexp

      yield sexp
    end
  end

  ##
  # Replaces all elements whose node_type is +from+ with +to+. Used
  # only for the most trivial of rewrites.

  def find_and_replace_all from, to
    each_with_index do | elem, index |
      if Sexp === elem then
        elem.find_and_replace_all(from, to)
      elsif elem == from
        self[index] = to
      end
    end
  end

  ##
  # Replaces all Sexps matching +pattern+ with Sexp +repl+.

  def gsub pattern, repl
    return repl if pattern == self

    new = self.map { |subset|
      case subset
      when Sexp then
        if Matcher === pattern && pattern.satisfy?(subset) then # TODO: make === be satisfy? maybe?
          repl.dup rescue repl
        else
          subset.gsub pattern, repl
        end
      else
        subset
      end
    }

    Sexp.from_array new
  end

  def inspect # :nodoc:
    sexp_str = self.map(&:inspect).join ", "
    if ENV["VERBOSE"] && line then
      "s(#{sexp_str}).line(#{line})"
    else
      "s(#{sexp_str})"
    end
  end

  def find_node name, delete = false # :nodoc:
    matches = find_nodes name

    case matches.size
    when 0 then
      nil
    when 1 then
      match = matches.first
      delete match if delete
      match
    else
      raise NoMethodError, "multiple nodes for #{name} were found in #{inspect}"
    end
  end

  ##
  # Find every node with type +name+.

  def find_nodes name
    each_sexp.find_all { |sexp| sexp.sexp_type == name }
  end

  UNASSIGNED = Object.new

  ##
  # If passed a line number, sets the line and returns self. Otherwise
  # returns the line number. This allows you to do message cascades
  # and still get the sexp back.

  def line n = UNASSIGNED
    if n != UNASSIGNED then
      raise ArgumentError, "setting %p.line %p" % [self, n] unless Integer === n
      @line = n
      self
    else
      @line ||= nil
    end
  end

  ##
  # Returns the maximum line number of the children of self.

  def line_max
    @line_max ||= self.deep_each.map(&:line).compact.max
  end

  ##
  # Returns the size of the sexp, flattened.

  def mass
    @mass ||= inject(1) { |t, s| Sexp === s ? t + s.mass : t }
  end

  ##
  # Returns the node named +node+, deleting it if +delete+ is true.

  def method_missing meth, delete = false
    r = find_node meth, delete
    if ENV["DEBUG"] then
      if r.nil? then
        warn "%p.method_missing(%p) => nil from %s" % [self, meth, caller.first]
      elsif ENV["VERBOSE"]
        warn "%p.method_missing(%p) from %s" % [self, meth, caller.first]
      end
    end
    r
  end

  def respond_to? msg, private = false # :nodoc:
    # why do I need this? Because ruby 2.0 is broken. That's why.
    super
  end

  def pretty_print q # :nodoc:
    nnd = ")"
    nnd << ".line(#{line})" if line && ENV["VERBOSE"]

    q.group(1, "s(", nnd) do
      q.seplist(self) {|v| q.pp v }
    end
  end

  ##
  # Returns the node type of the Sexp.

  def sexp_type
    first
  end

  ##
  # Sets the node type of the Sexp.

  def sexp_type= v
    self[0] = v
  end

  ##
  # Returns the Sexp body (starting at +from+, defaulting to 1), ie
  # the values without the node type.

  def sexp_body from = 1
    self.new._concat(self[from..-1] || [])
  end

  ##
  # Sets the Sexp body to new content.

  def sexp_body= v
    self[1..-1] = v
  end

  alias :head :sexp_type
  alias :rest :sexp_body

  ##
  # If run with debug, Sexp will raise if you shift on an empty
  # Sexp. Helps with debugging.

  def shift
    raise "I'm empty" if self.empty?
    super
  end if ($DEBUG or $TESTING)

  ##
  # Returns the bare bones structure of the sexp.
  # s(:a, :b, s(:c, :d), :e) => s(:a, s(:c))

  def structure
    if Array === self.sexp_type then
      warn "NOTE: form s(s(:subsexp)).structure is deprecated. Removing in 5.0"
      s(:bogus, *self).structure # TODO: remove >= 4.2.0
    else
      s(self.sexp_type, *each_sexp.map(&:structure))
    end
  end

  ##
  # Replaces the Sexp matching +pattern+ with +repl+.

  def sub pattern, repl
    return repl.dup if pattern == self
    return repl.dup if Matcher === pattern && pattern.satisfy?(self)

    done = false

    new = self.map do |subset|
      if done then
        subset
      else
        case subset
        when Sexp then
          if pattern == subset then
            done = true
            repl.dup rescue repl
          elsif Matcher === pattern && pattern.satisfy?(subset) then
            done = true
            repl.dup rescue repl
          else
            subset.sub pattern, repl
          end
        else
          subset
        end
      end
    end

    Sexp.from_array new
  end

  def to_a # :nodoc:
    self.map { |o| Sexp === o ? o.to_a : o }
  end

  alias to_s inspect # :nodoc:

  ##
  # Return the value (last item) of a single element sexp (eg `s(:lit, 42)`).

  def value
    raise "multi item sexp" if size > 2
    last
  end
end

##
# This is a very important shortcut to make using Sexps much more awesome.
#
# In its normal form +s(...)+, creates a Sexp instance. If passed a
# block, it creates a Sexp::Matcher using the factory methods on Sexp.
#
# See Matcher and other factory class methods on Sexp.

def s *args, &blk
  return Sexp.class_eval(&blk) if blk
  Sexp.new(*args)
end

require "sexp_matcher" unless defined? Sexp::Matcher
require "strict_sexp" if ENV["SP_DEBUG"] || ENV["STRICT_SEXP"].to_i > 0
