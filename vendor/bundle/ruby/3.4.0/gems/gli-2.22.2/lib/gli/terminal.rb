module GLI
  # Class to encapsulate stuff about the terminal. This is useful to application developers
  # as a canonical means to get information about the user's current terminal configuraiton.
  # GLI uses this to determine the number of columns to use when printing to the screen.
  #
  # To access it, use Terminal.instance.  This is a singleton mostly to facilitate testing, but
  # it seems reasonable enough, since there's only one terminal in effect
  #
  # Example:
  #
  #     Terminal.instance.size[0] # => columns in the terminal
  #     Terminal.default_size = [128,24] # => change default when we can't figure it out
  #     raise "no ls?!?!?" unless Terminal.instance.command_exists?("ls")
  #
  class Terminal

    @@default_size = [80,24]

    # Get the default size of the terminal when we can't figure it out
    # 
    # Returns an array of int [cols,rows]
    def self.default_size
      @@default_size
    end

    # Set the default size of the terminal to use when we can't figure it out
    #
    # +size+:: array of two int [cols,rows]
    def self.default_size=(size)
      @@default_size = size
    end

    # Provide access to the shared instance.  
    def self.instance; @@instance ||= Terminal.new; end

    # Call this to cause methods to throw exceptions rather than return a sane default.  You
    # probably don't want to call this unless you are writing tests
    def make_unsafe! #:nodoc:
      @unsafe = true
    end

    # Returns true if the given command exists on this system
    #
    # +command+:: The command, as a String, to check for, without any path information.
    def self.command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|dir| File.exist? File.join(dir, command) }
    end

    def command_exists?(command)
      self.class.command_exists?(command)
    end

    SIZE_DETERMINERS = [
      [
        lambda { (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/) },
        lambda { [ENV['COLUMNS'].to_i, ENV['LINES'].to_i] }
      ],
      [
        lambda { (jruby? || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput') },
        lambda { [run_command('tput cols').to_i, run_command('tput lines').to_i] }
      ],
      [
        lambda { (solaris? && STDIN.tty? && command_exists?('stty')) },
        lambda { run_command('stty').split("\n")[1].scan(/\d+/)[0..1].map { |size_element| size_element.to_i }.reverse }
      ],
      [ 
        lambda { STDIN.tty? && command_exists?('stty') },
        lambda { run_command('stty size').scan(/\d+/).map { |size_element| size_element.to_i }.reverse }
      ],
      [
        lambda { true },
        lambda { Terminal.default_size },
      ],
    ]

    # Get the size of the current terminal.
    # Ripped from hirb[https://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb]
    #
    # Returns an Array of size two Ints representing the terminal width and height
    def size
      SIZE_DETERMINERS.each do |predicate, get_size|
        next unless predicate.call
        size = get_size.call
        return size unless size == [0, 0]
      end
    rescue Exception => ex
      raise ex if @unsafe
      Terminal.default_size
    end

    private

    # Runs a command using backticks.  Extracted to allow for testing
    def self.run_command(command)
      `#{command}`
    end

    # True if we are JRuby; exposed to allow for testing
    def self.jruby?; RUBY_PLATFORM =~ /java/; end

    # True if this is running under Solaris Sparc
    def self.solaris?; RUBY_PLATFORM =~ /solaris/; end

  end
end
