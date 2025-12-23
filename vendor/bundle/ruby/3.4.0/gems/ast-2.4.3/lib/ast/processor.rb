module AST
  # This class includes {AST::Processor::Mixin}; however, it is
  # deprecated, since the module defines all of the behaviors that
  # the processor includes.  Any new libraries should use
  # {AST::Processor::Mixin} instead of subclassing this.
  #
  # @deprecated Use {AST::Processor::Mixin} instead.
  class Processor
    require_relative 'processor/mixin'
    include Mixin
  end
end
