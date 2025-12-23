require 'etc'
require 'optparse'
require 'gli/dsl'
require 'pathname'

module GLI
  # A means to define and parse a command line interface that works as
  # Git's does, in that you specify global options, a command name, command
  # specific options, and then command arguments.
  module App
    include DSL
    include AppSupport

    # Loads ruby files in the load path that start with
    # +path+, which are presumed to be commands for your executable.
    # This is useful for decomposing your bin file into different classes, but
    # can also be used as a plugin mechanism, allowing users to provide additional
    # commands for your app at runtime.  All that being said, it's basically
    # a glorified +require+.
    #
    # path:: a path from which to load <code>.rb</code> files that, presumably, contain commands.  If this is an absolute path,
    #        any files in that path are loaded.  If not, it is interpretted as relative to somewhere
    #        in the <code>LOAD_PATH</code>.
    #
    # == Example:
    #
    #     # loads *.rb from your app's install - great for decomposing your bin file
    #     commands_from "my_app/commands"
    #
    #     # loads *.rb files from the user's home dir - great and an extension/plugin mechanism
    #     commands_from File.join(ENV["HOME"],".my_app","plugins")
    def commands_from(path)
      if Pathname.new(path).absolute? and File.exist?(path)
        load_commands(path)
      else
        $LOAD_PATH.each do |load_path|
          commands_path = File.join(load_path,path)
          load_commands(commands_path)
        end
      end
    end

    # Describe the overall application/programm.  This should be a one-sentence summary
    # of what your program does that will appear in the help output.
    #
    # +description+:: A String of the short description of your program's purpose
    def program_desc(description=nil)
      if description
        @program_desc = description
      end
      @program_desc
    end

    # Provide a longer description of the program.  This can be as long as needed, and use double-newlines
    # for paragraphs.  This will show up in the help output.
    #
    # description:: A String for the description
    def program_long_desc(description=nil)
      if description
        @program_long_desc = description
      end
      @program_long_desc
    end

    # Provide a flag to choose whether to hide or not from the help the undescribed commands.
    # By default the undescribed commands will be shown in the help.
    #
    # hide:: A Bool for hide the undescribed commands
    def hide_commands_without_desc(hide=nil)
      unless hide.nil?
        @hide_commands_without_desc = hide
      end
      @hide_commands_without_desc || false
    end

    # Use this if the following command should not have the pre block executed.
    # By default, the pre block is executed before each command and can result in
    # aborting the call.  Using this will avoid that behavior for the following command
    def skips_pre
      @skips_pre = true
    end

    # Use this if the following command should not have the post block executed.
    # By default, the post block is executed after each command.
    # Using this will avoid that behavior for the following command
    def skips_post
      @skips_post = true
    end

    # Use this if the following command should not have the around block executed.
    # By default, the around block is executed, but for commands that might not want the
    # setup to happen, this can be handy
    def skips_around
      @skips_around = true
    end

    # Sets that this app uses a config file as well as the name of the config file.
    #
    # +filename+:: A String representing the path to the file to use for the config file.  If it's an absolute
    #              path, this is treated as the path to the file.  If it's *not*, it's treated as relative to the user's home
    #              directory as produced by <code>File.expand_path('~')</code>.
    def config_file(filename)
      if filename =~ /^\//
        @config_file = filename
      else
        @config_file = File.join(File.expand_path(ENV['HOME']),filename)
      end
      commands[:initconfig] = InitConfig.new(@config_file,commands,flags,switches)
      @commands_declaration_order << commands[:initconfig]
      @config_file
    end

    # Define a block to run after command line arguments are parsed
    # but before any command is run.  If this block raises an exception
    # the command specified will not be executed.
    # The block will receive the global-options,command,options, and arguments
    # If this block evaluates to true, the program will proceed; otherwise
    # the program will end immediately and exit nonzero
    def pre(&a_proc)
      @pre_block = a_proc
    end

    # Define a block to run after the command was executed, <b>only
    # if there was not an error</b>.
    # The block will receive the global-options,command,options, and arguments
    def post(&a_proc)
      @post_block = a_proc
    end

    # This inverts the pre/post concept.  This is useful when you have a global shared resource that is governed by a block
    # instead of separate open/close methods.  The block you pass here will be given four parameters:
    #
    # global options:: the parsed global options
    # command:: The GLI::Command that the user is going to invoke
    # options:: the command specific options
    # args:: unparsed command-line args
    # code:: a block that you must +call+ to execute the command.
    #
    # #help_now! and #exit_now! work as expected; you can abort the command call by simply not calling it.
    #
    # You can declare as many #around blocks as you want.  They will be called in the order in which they are defined.
    #
    # Note that if you declare #around blocks, #pre and #post blocks will still work.  The #pre is called first, followed by
    # the around, followed by the #post.
    #
    # Call #skips_around before a command that should not have this hook fired
    def around(&a_proc)
      @around_blocks ||= []
      @around_blocks << a_proc
    end

    # Define a block to run if an error occurs.
    # The block will receive any Exception that was caught.
    # It should evaluate to false to avoid the built-in error handling (which basically just
    # prints out a message). GLI uses a variety of exceptions that you can use to find out what
    # errors might've occurred during command-line parsing:
    # * GLI::CustomExit
    # * GLI::UnknownCommandArgument
    # * GLI::UnknownGlobalArgument
    # * GLI::UnknownCommand
    # * GLI::BadCommandLine
    def on_error(&a_proc)
      @error_block = a_proc
    end

    # Indicate the version of your application
    #
    # +version+:: String containing the version of your application.
    def version(version)
      @version = version
      desc 'Display the program version'
      switch :version, :negatable => false
    end

    # By default, GLI mutates the argument passed to it.  This is
    # consistent with +OptionParser+, but be less than ideal.  Since
    # that value, for scaffolded apps, is +ARGV+, you might want to
    # refer to the entire command-line via +ARGV+ and thus not want it mutated.
    def preserve_argv(preserve=true)
      @preserve_argv = preserve
    end

    # Call this with +true+ will cause the +global_options+ and
    # +options+ passed to your code to be wrapped in
    # Options, which is a subclass of +OpenStruct+ that adds
    # <tt>[]</tt> and <tt>[]=</tt> methods.
    #
    # +use_openstruct+:: a Boolean indicating if we should use OpenStruct instead of Hashes
    def use_openstruct(use_openstruct)
      @use_openstruct = use_openstruct
    end

    # Configure a type conversion not already provided by the underlying OptionParser.
    # This works more or less like the OptionParser version. It's global.
    #
    # object:: the class (or whatever) that triggers the type conversion
    # block:: the block that will be given the string argument and is expected
    #         to return the converted value
    #
    # Example
    #
    #     accept(Hash) do |value|
    #       result = {}
    #       value.split(/,/).each do |pair|
    #         k,v = pair.split(/:/)
    #         result[k] = v
    #       end
    #       result
    #     end
    #
    #     flag :properties, :type => Hash
    def accept(object,&block)
      accepts[object] = block
    end

    # Simpler means of exiting with a custom exit code.  This will
    # raise a CustomExit with the given message and exit code, which will ultimatley
    # cause your application to exit with the given exit_code as its exit status
    # Use #help_now! if you want to show the help in addition to the error message
    #
    # message:: message to show the user
    # exit_code:: exit code to exit as, defaults to 1
    def exit_now!(message,exit_code=1)
      raise CustomExit.new(message,exit_code)
    end

    # Exit now, showing the user help for the command they executed.  Use #exit_now! to just show the error message
    #
    # message:: message to indicate how the user has messed up the CLI invocation or nil to just simply show help
    def help_now!(message=nil)
      exception = OptionParser::ParseError.new(message)
      class << exception
        def exit_code; 64; end
      end
      raise exception
    end

    # Control how commands and options are sorted in help output.  By default, they are sorted alphabetically.
    #
    # sort_type:: How you want help commands/options sorted:
    #             +:manually+:: help commands/options are ordered in the order declared.
    #             +:alpha+:: sort alphabetically (default)
    def sort_help(sort_type)
      @help_sort_type = sort_type
    end

    # Set how help text is wrapped.
    #
    # wrap_type:: Symbol indicating how you'd like text wrapped:
    #             +:to_terminal+:: Wrap text based on the width of the terminal (default)
    #             +:verbatim+:: Format text exactly as it was given to the various methods.  This is useful if your output has
    #                           formatted output, e.g. ascii tables and you don't want it messed with.
    #             +:one_line+:: Do not wrap text at all.  This will bring all help content onto one line, removing any newlines
    #             +:tty_only+:: Wrap like +:to_terminal+ if this output is going to a TTY, otherwise don't wrap (like +:one_line+)
    def wrap_help_text(wrap_type)
      @help_text_wrap_type = wrap_type
    end

    # Control how the SYNOPSIS is formatted.
    #
    # format:: one of:
    #          +:full+:: the default, show subcommand options and flags inline
    #          +:terminal+:: if :full would be wider than the terminal, use :compact
    #          +:compact+:: use a simpler and shorter SYNOPSIS.  Useful if your app has a lot of options and showing them in the SYNOPSIS makes things more confusing
    def synopsis_format(format)
      @synopsis_format_type = format
    end

    def program_name(override=nil) #:nodoc:
      warn "#program_name has been deprecated"
    end

    # Sets a default command to run when none is specified on the command line.  Note that
    # if you use this, you won't be able to pass arguments, flags, or switches
    # to the command when run in default mode.  All flags and switches are treated
    # as global, and any argument will be interpretted as the command name and likely
    # fail.
    #
    # +command+:: Command as a Symbol to run as default
    def default_command(command)
      @default_command = command.to_sym
    end

    # How to handle subcommand options.  In general, you want to set this to +:normal+, which
    # treats each subcommand as establishing its own namespace for options.  This is what
    # the scaffolding should generate, but it is *not* what GLI 2.5.x and lower apps had as a default.
    # To maintain backwards compatibility, the default is +:legacy+, which is that all subcommands of
    # a particular command share a namespace for options, making it impossible for two subcommands
    # to have options of the same name.
    def subcommand_option_handling(handling_strategy)
      @subcommand_option_handling_strategy = handling_strategy
    end

    # How to handle argument validation.
    #
    # handling_strategy:: One of:
    #                     +:loose+:: no argument validation.  Use of `arg` or `arg_name` is for documentation purposes only.  (Default)
    #                     +:strict+:: arguments are validated according to their specification.  +action+ blocks may assume
    #                                 the value of `arguments` matches the specification provided in `arg`.  Note that to use
    #                                 this strategy, you must also be sure that +subcommand_option_handling+ is set.
    def arguments(handling_strategy)
      @argument_handling_strategy = handling_strategy
    end


    # Enables/Disables command autocomplete, where partially spelled commands are automatically expanded to their full form
    #
    # Example:
    # When enabled, executing 'shake' would execute 'shake_hand' (if no 'shake' command is defined).
    # When disabled, executing 'shake' would throw an UnknownCommand error
    #
    # +boolean+:: Boolean value to enable or disable autocomplete, respectively. True by default.
    def autocomplete_commands(boolean)
      @autocomplete = boolean
    end

    private

    def load_commands(path)
      if File.exist? path
        Dir.entries(path).sort.each do |entry|
          file = File.join(path,entry)
          if file =~ /\.rb$/
            require file
          end
        end
      end
    end
  end
end
