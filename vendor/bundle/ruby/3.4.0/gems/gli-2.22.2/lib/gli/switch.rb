require 'gli/command_line_option.rb'

module GLI
  # Defines a command line switch
  class Switch < CommandLineOption #:nodoc:

    attr_accessor :default_value
    attr_reader :negatable

    # Creates a new switch
    #
    # names - Array of symbols or strings representing the names of this switch
    # options - hash of options:
    #           :desc - the short description
    #           :long_desc - the long description
    #           :negatable - true or false if this switch is negatable; defaults to true
    #           :default_value - default value if the switch is omitted
    def initialize(names,options = {})
      super(names,options)
      @default_value = false if options[:default_value].nil?
      @negatable = options[:negatable].nil? ? true : options[:negatable]
      if @default_value != false && @negatable == false
        raise "A switch with default #{@default_value} that isn't negatable is useless"
      end
    end

    def arguments_for_option_parser
      all_forms_a
    end

    def negatable?
      @negatable
    end

    def required?
      false
    end
  end
end
