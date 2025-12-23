require 'gli/command_line_option.rb'

module GLI
  # Defines a flag, which is to say a switch that takes an argument
  class Flag < CommandLineOption # :nodoc:

    # Regexp that is used to see if the flag's argument matches
    attr_reader :must_match

    # Type to which we want to cast the values
    attr_reader :type

    # Name of the argument that user configured
    attr_reader :argument_name

    # Creates a new option
    #
    # names:: Array of symbols or strings representing the names of this switch
    # options:: hash of options:
    #           :desc:: the short description
    #           :long_desc:: the long description
    #           :default_value:: the default value of this option
    #           :arg_name:: the name of the flag's argument, default is "arg"
    #           :must_match:: a regexp that the flag's value must match
    #           :type:: a class to convert the value to
    #           :required:: if true, this flag must be specified on the command line
    #           :multiple:: if true, flag may be used multiple times and values are stored in an array
    #           :mask:: if true, the default value of this flag will not be output in the help.
    #                   This is useful for password flags where you might not want to show it
    #                   on the command-line.
    def initialize(names,options)
      super(names,options)
      @argument_name = options[:arg_name] || "arg"
      @must_match = options[:must_match]
      @type = options[:type]
      @mask = options[:mask]
      @required = options[:required]
      @multiple = options[:multiple]
    end

    # True if this flag is required on the command line
    def required?
      @required
    end

    # True if the flag may be used multiple times.
    def multiple?
      @multiple
    end

    def safe_default_value
      if @mask
        "********"
      else
        # This uses @default_value instead of the `default_value` method because
        # this method is only used for display, and for flags that may be passed
        # multiple times, we want to display whatever is set in the code as the
        # the default, or the string "none" rather than displaying an empty
        # array.
        @default_value
      end
    end

    # The default value for this flag. Uses the value passed if one is set;
    # otherwise uses `[]` if the flag support multiple arguments and `nil` if
    # it does not.
    def default_value
      if @default_value
        @default_value
      elsif @multiple
        []
      end
    end

    def arguments_for_option_parser
      args = all_forms_a.map { |name| "#{name} VAL" }
      args << @must_match if @must_match
      args << @type if @type
      args
    end

    # Returns a string of all possible forms
    # of this flag.  Mostly intended for printing
    # to the user.
    def all_forms(joiner=', ')
      forms = all_forms_a
      string = forms.join(joiner)
      if forms[-1] =~ /^\-\-/
        string += '='
      else
        string += ' '
      end
      string += @argument_name
      return string
    end
  end
end
