module GLI
  class OptionParsingResult
    attr_accessor :global_options
    attr_accessor :command
    attr_accessor :command_options
    attr_accessor :arguments

    def convert_to_openstruct!
      @global_options  = Options.new(@global_options)
      @command_options = Options.new(@command_options)
      self
    end

    # Allows us to splat this object into blocks and methods expecting parameters in this order
    def to_a
      [@global_options,@command,@command_options,@arguments]
    end
  end
end
