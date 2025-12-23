require 'stringio'
require 'gli/commands/help_modules/arg_name_formatter'
module GLI
  module Commands
    class RdocDocumentListener

      def initialize(global_options,options,arguments,app)
        @app = app
        @io = File.new("#{app.exe_name}.rdoc",'w')
        @nest = ''
        @arg_name_formatter = GLI::Commands::HelpModules::ArgNameFormatter.new
      end

      def beginning
      end

      # Called when processing has completed
      def ending
        @io.close
      end

      # Gives you the program description
      def program_desc(desc)
        @io.puts "== #{@app.exe_name} - #{desc}"
        @io.puts
      end

      def program_long_desc(desc)
        @io.puts desc
        @io.puts
      end

      # Gives you the program version
      def version(version)
        @io.puts "v#{version}"
        @io.puts
      end

      def options
        if @nest.size == 0
          @io.puts "=== Global Options"
        else
          @io.puts "#{@nest}=== Options"
        end
      end

      # Gives you a flag in the current context
      def flag(name,aliases,desc,long_desc,default_value,arg_name,must_match,type)
        invocations = ([name] + Array(aliases)).map { |_| add_dashes(_) }.join('|')
        usage = "#{invocations} #{arg_name || 'arg'}"
        @io.puts "#{@nest}=== #{usage}"
        @io.puts
        @io.puts String(desc).strip
        @io.puts
        @io.puts "[Default Value] #{default_value || 'None'}"
        @io.puts "[Must Match] #{must_match.to_s}" unless must_match.nil?
        @io.puts String(long_desc).strip
        @io.puts
      end

      # Gives you a switch in the current context
      def switch(name,aliases,desc,long_desc,negatable)
        if negatable
          name = "[no-]#{name}" if name.to_s.length > 1
          aliases = aliases.map { |_|  _.to_s.length > 1 ? "[no-]#{_}" : _ } 
        end
        invocations = ([name] + aliases).map { |_| add_dashes(_) }.join('|')
        @io.puts "#{@nest}=== #{invocations}"
        @io.puts String(desc).strip
        @io.puts
        @io.puts String(long_desc).strip
        @io.puts
      end

      def end_options
      end

      def commands
        @io.puts "#{@nest}=== Commands"
        @nest = "#{@nest}="
      end

      # Gives you a command in the current context and creates a new context of this command
      def command(name,aliases,desc,long_desc,arg_name,arg_options)
        @io.puts "#{@nest}=== Command: <tt>#{([name] + aliases).join('|')} #{@arg_name_formatter.format(arg_name,arg_options,[])}</tt>"
        @io.puts String(desc).strip
        @io.puts 
        @io.puts String(long_desc).strip
        @nest = "#{@nest}="
      end

      # Ends a command, and "pops" you back up one context
      def end_command(name)
        @nest.gsub!(/=$/,'')
      end

      # Gives you the name of the current command in the current context
      def default_command(name)
        @io.puts "[Default Command] #{name}" unless name.nil?
      end

      def end_commands
        @nest.gsub!(/=$/,'')
      end

    private

      def add_dashes(name)
        name = "-#{name}"
        name = "-#{name}" if name.length > 2
        name
      end


    end
  end
end
