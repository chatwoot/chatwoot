require 'gli/command_line_token.rb'

module GLI
  # An option, not a command or argument, on the command line
  class CommandLineOption < CommandLineToken #:nodoc:

    attr_accessor :default_value
    # Command to which this option "belongs", nil if it's a global option
    attr_accessor :associated_command

    # Creates a new option
    #
    # names - Array of symbols or strings representing the names of this switch
    # options - hash of options:
    #           :desc - the short description
    #           :long_desc - the long description
    #           :default_value - the default value of this option
    def initialize(names,options = {})
      super(names,options[:desc],options[:long_desc])
      @default_value = options[:default_value]
    end

    def self.name_as_string(name,negatable=true)
      string = name.to_s
      if string.length == 1 
        "-#{string}" 
      elsif negatable
        "--[no-]#{string}"
      else
        "--#{string}"
      end
    end
  end
end
