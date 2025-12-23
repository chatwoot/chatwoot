module GLI
  module Commands
    # Takes a DocListener which will be called with all of the meta-data and documentation
    # about your app, so as to create documentation in whatever format you want
    class Doc < Command
      FORMATS = {
        'rdoc' => GLI::Commands::RdocDocumentListener
      }
      # Create the Doc generator based on the GLI app passed in
      def initialize(app)
        super(:names       => "_doc",
              :description => "Generate documentation of your application's UI",
              :long_desc   => "Introspects your application's UI meta-data to generate documentation in a variety of formats.  This is intended to be extensible via the DocumentListener interface, so that you can provide your own documentation formats without them being a part of GLI",
              :skips_pre   => true, :skips_post => true, :skips_around => true, :hidden => true)

        @app = app
        @parent = @app
        @subcommand_option_handling_strategy = @app.subcommand_option_handling_strategy

        desc          'The format name of the documentation to generate or the class name to use to generate it'
        default_value 'rdoc'
        arg_name      'name_or_class'
        flag          :format

        action do |global_options,options,arguments|
          self.document(format_class(options[:format]).new(global_options,options,arguments,app))
        end
      end

      def nodoc
        true
      end

      # Generates documentation using the listener
      def document(document_listener)
        document_listener.beginning
        document_listener.program_desc(@app.program_desc) unless @app.program_desc.nil?
        document_listener.program_long_desc(@app.program_long_desc) unless @app.program_long_desc.nil?
        document_listener.version(@app.version_string)
        if any_options?(@app)
          document_listener.options 
        end
        document_flags_and_switches(document_listener,
                                    @app.flags.values.sort(&by_name),
                                    @app.switches.values.sort(&by_name))
        if any_options?(@app)
          document_listener.end_options 
        end
        document_listener.commands
        document_commands(document_listener,@app)
        document_listener.end_commands
        document_listener.ending
      end

      # Interface for a listener that is called during various parts of the doc process
      class DocumentListener
        def initialize(global_options,options,arguments,app)
          @global_options = global_options
          @options        = options
          @arguments      = arguments
          @app            = app
        end
        # Called before processing begins
        def beginning
          abstract!
        end

        # Called when processing has completed
        def ending
          abstract!
        end

        # Gives you the program description
        def program_desc(desc)
          abstract!
        end

        # Gives you the program long description
        def program_long_desc(desc)
          abstract!
        end

        # Gives you the program version
        def version(version)
          abstract!
        end

        # Called at the start of options for the current context
        def options
          abstract!
        end

        # Called when all options for the current context have been vended
        def end_options
          abstract!
        end

        # Called at the start of commands for the current context
        def commands
          abstract!
        end

        # Called when all commands for the current context have been vended
        def end_commands
          abstract!
        end

        # Gives you a flag in the current context
        def flag(name,aliases,desc,long_desc,default_value,arg_name,must_match,type)
          abstract!
        end

        # Gives you a switch in the current context
        def switch(name,aliases,desc,long_desc,negatable)
          abstract!
        end

        # Gives you the name of the current command in the current context
        def default_command(name)
          abstract!
        end

        # Gives you a command in the current context and creates a new context of this command
        def command(name,aliases,desc,long_desc,arg_name,arg_options)
          abstract!
        end

        # Ends a command, and "pops" you back up one context
        def end_command(name)
          abstract!
        end

      private
        def abstract!
          raise "Subclass must implement"
        end
      end

    private

      def format_class(format_name)
        FORMATS.fetch(format_name) {
          begin
            return format_name.split(/::/).reduce(Kernel) { |context,part| context.const_get(part) }
          rescue => ex
            raise IndexError,"Couldn't find formatter or class named #{format_name}"
          end
        }
      end

      def document_commands(document_listener,context)
        context.commands.values.reject {|_| _.nodoc }.sort(&by_name).each do |command|
          call_command_method_being_backwards_compatible(document_listener,command)
          document_listener.options if any_options?(command)
          document_flags_and_switches(document_listener,command_flags(command),command_switches(command))
          document_listener.end_options if any_options?(command)
          document_listener.commands if any_commands?(command)
          document_commands(document_listener,command)
          document_listener.end_commands if any_commands?(command)
          document_listener.end_command(command.name)
        end
        document_listener.default_command(context.get_default_command)
      end

      def call_command_method_being_backwards_compatible(document_listener,command)
        command_args = [command.name,
                        Array(command.aliases),
                        command.description,
                        command.long_description,
                        command.arguments_description]
        if document_listener.method(:command).arity >= 6
          command_args << command.arguments_options
          if document_listener.method(:command).arity >= 7
            command_args << command.arguments
          end
          if document_listener.method(:command).arity >= 8
            command_args << command.examples
          end
        end
        document_listener.command(*command_args)
      end

      def by_name
        lambda { |a,b| a.name.to_s <=> b.name.to_s }
      end

      def command_flags(command)
        if @subcommand_option_handling_strategy == :legacy
          command.topmost_ancestor.flags.values.select { |flag| flag.associated_command == command }.sort(&by_name)
        else
          command.flags.values.sort(&by_name)
        end
      end

      def command_switches(command)
        if @subcommand_option_handling_strategy == :legacy
          command.topmost_ancestor.switches.values.select { |switch| switch.associated_command == command }.sort(&by_name)
        else
          command.switches.values.sort(&by_name)
        end
      end

      def document_flags_and_switches(document_listener,flags,switches)
        flags.each do |flag|
          document_listener.flag(flag.name,
                                 Array(flag.aliases),
                                 flag.description,
                                 flag.long_description,
                                 flag.safe_default_value,
                                 flag.argument_name,
                                 flag.must_match,
                                 flag.type)
        end
        switches.each do |switch|
          document_listener.switch(switch.name,
                                   Array(switch.aliases),
                                   switch.description,
                                   switch.long_description,
                                   switch.negatable)
        end
      end

      def any_options?(context)
        options = if context.kind_of?(Command)
                    command_flags(context) + command_switches(context)
                  else
                    context.flags.values + context.switches.values
                  end
        !options.empty?
      end

      def any_commands?(command)
        !command.commands.empty?
      end
    end
  end
end
