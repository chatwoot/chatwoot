# frozen_string_literal: true

# This private class encapsulates pairs (mod, cname).
#
# Objects represent the constant cname in the class or module object mod, and
# have API to manage them that encapsulates the constants API. Examples:
#
#   cref.path
#   cref.set(value)
#   cref.get
#
# The constant may or may not exist in mod.
class Zeitwerk::Cref
  include Zeitwerk::RealModName

  # @sig Symbol
  attr_reader :cname

  # The type of the first argument is Module because Class < Module, class
  # objects are also valid.
  #
  # @sig (Module, Symbol) -> void
  def initialize(mod, cname)
    @mod   = mod
    @cname = cname
    @path  = nil
  end

  if Symbol.method_defined?(:name)
    # Symbol#name was introduced in Ruby 3.0. It returns always the same
    # frozen object, so we may save a few string allocations.
    #
    # @sig () -> String
    def path
      @path ||= Object.equal?(@mod) ? @cname.name : "#{real_mod_name(@mod)}::#{@cname.name}"
    end
  else
    # @sig () -> String
    def path
      @path ||= Object.equal?(@mod) ? @cname.to_s : "#{real_mod_name(@mod)}::#{@cname}"
    end
  end

  # The autoload? predicate takes into account the ancestor chain of the
  # receiver, like const_defined? and other methods in the constants API do.
  #
  # For example, given
  #
  #   class A
  #     autoload :X, "x.rb"
  #   end
  #
  #   class B < A
  #   end
  #
  # B.autoload?(:X) returns "x.rb".
  #
  # We need a way to retrieve it ignoring ancestors.
  #
  # @sig () -> String?
  if method(:autoload?).arity == 1
    # @sig () -> String?
    def autoload?
      @mod.autoload?(@cname) if self.defined?
    end
  else
    # @sig () -> String?
    def autoload?
      @mod.autoload?(@cname, false)
    end
  end

  # @sig (String) -> bool
  def autoload(abspath)
    @mod.autoload(@cname, abspath)
  end

  # @sig () -> bool
  def defined?
    @mod.const_defined?(@cname, false)
  end

  # @sig (Object) -> Object
  def set(value)
    @mod.const_set(@cname, value)
  end

  # @raise [NameError]
  # @sig () -> Object
  def get
    @mod.const_get(@cname, false)
  end

  # @raise [NameError]
  # @sig () -> void
  def remove
    @mod.__send__(:remove_const, @cname)
  end
end
