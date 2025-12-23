# :stopdoc:
# WHY do I have to do this?!?
class Regexp
  ONCE = 0 unless defined? ONCE # FIX: remove this - it makes no sense

  unless defined? ENC_NONE then
    ENC_NONE = /x/n.options
    ENC_EUC  = /x/e.options
    ENC_SJIS = /x/s.options
    ENC_UTF8 = /x/u.options
  end
end
# :startdoc:

class Array
  def prepend *vals
    self[0,0] = vals
  end
end unless [].respond_to?(:prepend)

# :stopdoc:
class Symbol
  def end_with? o
    self.to_s.end_with? o
  end
end unless :woot.respond_to?(:end_with?)
# :startdoc:

############################################################
# HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK

class String
  def clean_caller
    self.sub(File.dirname(__FILE__), "./lib").sub(/:in.*/, "")
  end if $DEBUG
end

require "sexp"

class Sexp
  attr_writer :paren # TODO: retire

  def paren
    @paren ||= false
  end

  def block_pass?
    any? { |s| Sexp === s && s.sexp_type == :block_pass }
  end
end

# END HACK
############################################################
