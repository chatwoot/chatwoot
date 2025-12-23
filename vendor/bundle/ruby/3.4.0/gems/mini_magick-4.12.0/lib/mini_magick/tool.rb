require "mini_magick/shell"

module MiniMagick
  ##
  # Abstract class that wraps command-line tools. It shouldn't be used directly,
  # but through one of its subclasses (e.g. {MiniMagick::Tool::Mogrify}). Use
  # this class if you want to be closer to the metal and execute ImageMagick
  # commands directly, but still with a nice Ruby interface.
  #
  # @example
  #   MiniMagick::Tool::Mogrify.new do |builder|
  #     builder.resize "500x500"
  #     builder << "path/to/image.jpg"
  #   end
  #
  class Tool

    CREATION_OPERATORS = %w[xc canvas logo rose gradient radial-gradient plasma
                            pattern text pango]

    ##
    # Aside from classic instantiation, it also accepts a block, and then
    # executes the command in the end.
    #
    # @example
    #   version = MiniMagick::Tool::Identify.new { |b| b.version }
    #   puts version
    #
    # @return [MiniMagick::Tool, String] If no block is given, returns an
    #   instance of the tool, if block is given, returns the output of the
    #   command.
    #
    def self.new(*args)
      instance = super(*args)

      if block_given?
        yield instance
        instance.call
      else
        instance
      end
    end

    # @private
    attr_reader :name, :args

    # @param name [String]
    # @param options [Hash]
    # @option options [Boolean] :whiny Whether to raise errors on non-zero
    #   exit codes.
    # @example
    #   MiniMagick::Tool::Identify.new(whiny: false) do |identify|
    #     identify.help # returns exit status 1, which would otherwise throw an error
    #   end
    def initialize(name, options = {})
      warn "MiniMagick::Tool.new(false) is deprecated and will be removed in MiniMagick 5, use MiniMagick::Tool.new(whiny: false) instead." if !options.is_a?(Hash)

      @name  = name
      @args  = []
      @whiny = options.is_a?(Hash) ? options.fetch(:whiny, MiniMagick.whiny) : options
    end

    ##
    # Executes the command that has been built up.
    #
    # @example
    #   mogrify = MiniMagick::Tool::Mogrify.new
    #   mogrify.resize("500x500")
    #   mogrify << "path/to/image.jpg"
    #   mogrify.call # executes `mogrify -resize 500x500 path/to/image.jpg`
    #
    # @example
    #   mogrify = MiniMagick::Tool::Mogrify.new
    #   # build the command
    #   mogrify.call do |stdout, stderr, status|
    #     # ...
    #   end
    #
    # @yield [Array] Optionally yields stdout, stderr, and exit status
    #
    # @return [String] Returns the output of the command
    #
    def call(*args)
      options = args[-1].is_a?(Hash) ? args.pop : {}
      warn "Passing whiny to MiniMagick::Tool#call is deprecated and will be removed in MiniMagick 5, use MiniMagick::Tool.new(whiny: false) instead." if args.any?
      whiny = args.fetch(0, @whiny)

      options[:whiny] = whiny
      options[:stderr] = false if block_given?

      shell = MiniMagick::Shell.new
      stdout, stderr, status = shell.run(command, options)
      yield stdout, stderr, status if block_given?

      stdout.chomp("\n")
    end

    ##
    # The currently built-up command.
    #
    # @return [Array<String>]
    #
    # @example
    #   mogrify = MiniMagick::Tool::Mogrify.new
    #   mogrify.resize "500x500"
    #   mogrify.contrast
    #   mogrify.command #=> ["mogrify", "-resize", "500x500", "-contrast"]
    #
    def command
      [*executable, *args]
    end

    ##
    # The executable used for this tool. Respects
    # {MiniMagick::Configuration#cli}, {MiniMagick::Configuration#cli_path},
    # and {MiniMagick::Configuration#cli_prefix}.
    #
    # @return [Array<String>]
    #
    # @example
    #   MiniMagick.configure { |config| config.cli = :graphicsmagick }
    #   identify = MiniMagick::Tool::Identify.new
    #   identify.executable #=> ["gm", "identify"]
    #
    # @example
    #   MiniMagick.configure do |config|
    #     config.cli = :graphicsmagick
    #     config.cli_prefix = ['firejail', '--force']
    #   end
    #   identify = MiniMagick::Tool::Identify.new
    #   identify.executable #=> ["firejail", "--force", "gm", "identify"]
    #
    def executable
      exe = [name]
      exe.unshift "magick" if MiniMagick.imagemagick7? && name != "magick"
      exe.unshift "gm" if MiniMagick.graphicsmagick?
      exe.unshift File.join(MiniMagick.cli_path, exe.shift) if MiniMagick.cli_path
      Array(MiniMagick.cli_prefix).reverse_each { |p| exe.unshift p } if MiniMagick.cli_prefix
      exe
    end

    ##
    # Appends raw options, useful for appending image paths.
    #
    # @return [self]
    #
    def <<(arg)
      args << arg.to_s
      self
    end

    ##
    # Merges a list of raw options.
    #
    # @return [self]
    #
    def merge!(new_args)
      new_args.each { |arg| self << arg }
      self
    end

    ##
    # Changes the last operator to its "plus" form.
    #
    # @example
    #   MiniMagick::Tool::Mogrify.new do |mogrify|
    #     mogrify.antialias.+
    #     mogrify.distort.+("Perspective", "0,0,4,5 89,0,45,46")
    #   end
    #   # executes `mogrify +antialias +distort Perspective '0,0,4,5 89,0,45,46'`
    #
    # @return [self]
    #
    def +(*values)
      args[-1] = args[-1].sub(/^-/, '+')
      self.merge!(values)
      self
    end

    ##
    # Create an ImageMagick stack in the command (surround.
    #
    # @example
    #   MiniMagick::Tool::Convert.new do |convert|
    #     convert << "wand.gif"
    #     convert.stack do |stack|
    #       stack << "wand.gif"
    #       stack.rotate(30)
    #     end
    #     convert.append.+
    #     convert << "images.gif"
    #   end
    #   # executes `convert wand.gif \( wizard.gif -rotate 30 \) +append images.gif`
    #
    def stack(*args)
      self << "("
      args.each do |value|
        case value
        when Hash   then value.each { |key, value| send(key, *value) }
        when String then self << value
        end
      end
      yield self if block_given?
      self << ")"
    end

    ##
    # Adds ImageMagick's pseudo-filename `-` for standard input.
    #
    # @example
    #   identify = MiniMagick::Tool::Identify.new
    #   identify.stdin
    #   identify.call(stdin: image_content)
    #   # executes `identify -` with the given standard input
    #
    def stdin
      self << "-"
    end

    ##
    # Adds ImageMagick's pseudo-filename `-` for standard output.
    #
    # @example
    #   content = MiniMagick::Tool::Convert.new do |convert|
    #     convert << "input.jpg"
    #     convert.auto_orient
    #     convert.stdout
    #   end
    #   # executes `convert input.jpg -auto-orient -` which returns file contents
    #
    def stdout
      self << "-"
    end

    ##
    # Define creator operator methods
    #
    # @example
    #   mogrify = MiniMagick::Tool.new("mogrify")
    #   mogrify.canvas("khaki")
    #   mogrify.command.join(" ") #=> "mogrify canvas:khaki"
    #
    CREATION_OPERATORS.each do |operator|
      define_method(operator.tr('-', '_')) do |value = nil|
        self << "#{operator}:#{value}"
        self
      end
    end

    ##
    # This option is a valid ImageMagick option, but it's also a Ruby method,
    # so we need to override it so that it correctly acts as an option method.
    #
    def clone(*args)
      self << '-clone'
      self.merge!(args)
      self
    end

    ##
    # Any undefined method will be transformed into a CLI option
    #
    # @example
    #   mogrify = MiniMagick::Tool.new("mogrify")
    #   mogrify.adaptive_blur("...")
    #   mogrify.foo_bar
    #   mogrify.command.join(" ") # => "mogrify -adaptive-blur ... -foo-bar"
    #
    def method_missing(name, *args)
      option = "-#{name.to_s.tr('_', '-')}"
      self << option
      self.merge!(args)
      self
    end

    def self.option_methods
      @option_methods ||= (
        tool = new(whiny: false)
        tool << "-help"
        help_page = tool.call(stderr: false)

        cli_options = help_page.scan(/^\s+-[a-z\-]+/).map(&:strip)
        if tool.name == "mogrify" && MiniMagick.graphicsmagick?
          # These options were undocumented before 2015-06-14 (see gm bug 302)
          cli_options |= %w[-box -convolve -gravity -linewidth -mattecolor -render -shave]
        end

        cli_options.map { |o| o[1..-1].tr('-','_') }
      )
    end

  end
end

require "mini_magick/tool/animate"
require "mini_magick/tool/compare"
require "mini_magick/tool/composite"
require "mini_magick/tool/conjure"
require "mini_magick/tool/convert"
require "mini_magick/tool/display"
require "mini_magick/tool/identify"
require "mini_magick/tool/import"
require "mini_magick/tool/magick"
require "mini_magick/tool/mogrify"
require "mini_magick/tool/mogrify_restricted"
require "mini_magick/tool/montage"
require "mini_magick/tool/stream"
