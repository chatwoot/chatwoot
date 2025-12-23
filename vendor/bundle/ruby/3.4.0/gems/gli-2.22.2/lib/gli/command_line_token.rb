module GLI
  # Abstract base class for a logical element of a command line, mostly so that subclasses can have similar
  # initialization and interface
  class CommandLineToken
    attr_reader :name #:nodoc:
    attr_reader :aliases #:nodoc:
    attr_reader :description #:nodoc:
    attr_reader :long_description #:nodoc:

    def initialize(names,description,long_description=nil) #:nodoc:
      @description = description
      @long_description = long_description
      @name,@aliases,@names = parse_names(names)
    end

    # Sort based on primary name
    def <=>(other)
      self.name.to_s <=> other.name.to_s
    end

    # Array of the name and aliases, as string
    def names_and_aliases
      [self.name,self.aliases].flatten.compact.map(&:to_s)
    end

    private
    # Returns a string of all possible forms
    # of this flag.  Mostly intended for printing
    # to the user.
    def all_forms(joiner=', ')
      forms = all_forms_a
      forms.join(joiner)
    end


    # Handles dealing with the "names" param, parsing
    # it into the primary name and aliases list
    def parse_names(names)
      # Allow strings; convert to symbols
      names = [names].flatten.map { |name| name.to_sym } 
      names_hash = {}
      names.each do |name| 
        raise ArgumentError.new("#{name} has spaces; they are not allowed") if name.to_s =~ /\s/
        names_hash[self.class.name_as_string(name)] = true
      end
      name = names.shift
      aliases = names.length > 0 ? names : nil
      [name,aliases,names_hash]
    end

    def negatable?
      false;
    end

    def all_forms_a
      forms = [self.class.name_as_string(name,negatable?)]
      if aliases
        forms |= aliases.map { |one_alias| self.class.name_as_string(one_alias,negatable?) }.sort { |one,two| one.length <=> two.length }
      end
      forms
    end
  end
end
