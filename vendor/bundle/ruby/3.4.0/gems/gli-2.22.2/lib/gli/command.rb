require 'gli/command_line_token.rb'
require 'gli/dsl.rb'

module GLI
  # A command to be run, in context of global flags and switches.  You are given an instance of this class
  # to the block you use for GLI::DSL#command.  This class mixes in GLI::DSL so all of those methods are available
  # to describe the command, in addition to the methods documented here, most importantly
  # #action.
  #
  # Example:
  #
  #     command :list do |c| # <- c is an instance of GLI::Command
  #       c.desc 'use long form'
  #       c.switch :l
  #
  #       c.action do |global,options,args|
  #         # list things here
  #       end
  #
  #       c.command :tasks do |t| # <- t is an instance of GLI::Command
  #         # this is a "subcommand" of list
  #         
  #         t.action do |global,options,args|
  #           # do whatever list tasks should do
  #         end
  #       end
  #     end
  #
  class Command < CommandLineToken
    include DSL
    include CommandSupport

    class ParentKey
      def to_sym
        "__parent__".to_sym
      end
    end

    # Key in an options hash to find the parent's parsed options.  Note that if you are
    # using openstruct, e.g. via `use_openstruct true` in your app setup, you will need
    # to use the method `__parent__` to access parent parsed options.
    PARENT = ParentKey.new

    # Create a new command.
    #
    # options:: Keys should be:
    #           +names+:: A String, Symbol, or Array of String or Symbol that represents the name(s) of this command (required).
    #           +description+:: short description of this command as a String
    #           +arguments_name+:: description of the arguments as a String, or nil if this command doesn't take arguments
    #           +long_desc+:: a longer description of the command, possibly with multiple lines.  A double line-break is treated
    #                         as a paragraph break.  No other formatting is respected, though inner whitespace is maintained.
    #           +skips_pre+:: if true, this command advertises that it doesn't want the pre block called first
    #           +skips_post+:: if true, this command advertises that it doesn't want the post block called after it
    #           +skips_around+:: if true, this command advertises that it doesn't want the around block called
    #           +hide_commands_without_desc+:: if true and there isn't a description the command is not going to be shown in the help
    #           +examples+:: An array of Hashes, where each hash must have the key +:example+ mapping to a string, and may optionally have the key +:desc+
    #                        that documents that example.
    def initialize(options)
      super(options[:names],options[:description],options[:long_desc])
      @arguments_description = options[:arguments_name] || ''
      @arguments_options = Array(options[:arguments_options]).flatten
      @arguments = options[:arguments] || []
      @skips_pre = options[:skips_pre]
      @skips_post = options[:skips_post]
      @skips_around = options[:skips_around]
      @hide_commands_without_desc = options[:hide_commands_without_desc]
      @commands_declaration_order = []
      @flags_declaration_order = []
      @switches_declaration_order = []
      @examples = options[:examples] || []
      clear_nexts
    end

    # Specify an example invocation.
    #
    # example_invocation:: test of a complete command-line invocation you want to show
    # options:: refine the example:
    #           +:desc+:: A description of the example to be shown with it (optional)
    def example(example_invocation,options = {})
      @examples << {
        example: example_invocation
      }.merge(options)
    end

    # Set the default command if this command has subcommands and the user doesn't 
    # provide a subcommand when invoking THIS command.  When nil, this will show an error and the help
    # for this command; when set, the command with this name will be executed.
    #
    # +command_name+:: The primary name of the subcommand of this command that should be run by default as a String or Symbol.
    def default_command(command_name)
      @default_command = command_name
    end

    # Define the action to take when the user executes this command.  Every command should either define this 
    # action block, or have subcommands (or both).
    #
    # +block+:: A block of code to execute.  The block will be given 3 arguments:
    #           +global_options+:: A Hash of the _global_ options specified
    #                              by the user, with defaults set and config file values used (if using a config file, see
    #                              GLI::App#config_file)
    #           +options+:: A Hash of the command-specific options specified by the 
    #                       user, with defaults set and config file values used (if using a config file, see 
    #                       GLI::App#config_file).
    #           +arguments+:: An Array of Strings representing the unparsed command line arguments
    #           The block's result value is not used; raise an exception or use GLI#exit_now! if you need an early exit based
    #           on an error condition
    #
    def action(&block)
      @action = block
    end

    # Describes this commands action block when it *also* has subcommands.
    # In this case, the GLI::DSL#desc value is the general description of the commands
    # that this command groups, and the value for *this* method documents what
    # will happen if you omit a subcommand.
    #
    # Note that if you omit the action block and specify a subcommand, that subcommand's
    # description will be used to describe what happens by default.
    #
    # desc:: the description of what this command's action block does.
    #
    # Example
    #
    #     desc 'list things'
    #     command :list do |c|
    #
    #       c.desc 'list tasks'
    #       c.command :tasks do |t|
    #         t.action do |global,options,args|
    #         end
    #       end
    #
    #       c.desc 'list contexts'
    #       c.command :contexts do |t|
    #         t.action do |global,options,args|
    #         end
    #       end
    #
    #       c.default_desc 'list both tasks and contexts'
    #       c.action do |global,options,args|
    #         # list everything
    #       end
    #     end
    #
    #
    #     > todo help list
    #     NAME
    #         list - List things
    #     
    #     SYNOPSIS
    #         todo [global options] list [command options] 
    #         todo [global options] list [command options]  tasks
    #         todo [global options] list [command options]  contexts
    #     
    #     COMMANDS
    #         <default> - list both tasks and contexts
    #         tasks     - list tasks
    #         contexts  - list contexts
    #
    def default_desc(desc)
      @default_desc = desc
    end

    # Returns true if this command has the given option defined
    def has_option?(option) #:nodoc:
      option = option.gsub(/^\-+/,'')
      ((flags.values.map { |_| [_.name,_.aliases] }) + 
       (switches.values.map { |_| [_.name,_.aliases] })).flatten.map(&:to_s).include?(option)
    end

    # Returns full name for help command including parents
    #
    # Example
    #
    #   command :remote do |t|
    #     t.command :add do |global,options,args|
    #     end
    #   end
    #
    #   @add_command.name_for_help # => ["remote", "add"]
    #
    def name_for_help
      name_array = [name.to_s]
      command_parent = parent
      while(command_parent.is_a?(GLI::Command)) do
        name_array.unshift(command_parent.name.to_s)
        command_parent = command_parent.parent
      end
      name_array
    end

    def self.name_as_string(name,negatable=false) #:nodoc:
      name.to_s
    end
  end
end
