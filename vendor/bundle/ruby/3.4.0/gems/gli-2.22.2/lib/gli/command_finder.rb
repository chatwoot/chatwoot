module GLI
  class CommandFinder
    attr_accessor :options

    DEFAULT_OPTIONS = {
      :default_command => nil,
      :autocomplete    => true
    }

    def initialize(commands, options = {})
      self.options = DEFAULT_OPTIONS.merge(options)
      self.commands_with_aliases = expand_with_aliases(commands)
    end

    def find_command(name)
      name = String(name || options[:default_command]).strip
      raise UnknownCommand.new("No command name given nor default available") if name == ''

      command_found = commands_with_aliases.fetch(name) do |command_to_match|
        if options[:autocomplete]
          found_match = find_command_by_partial_name(commands_with_aliases, command_to_match)
          if found_match.kind_of? GLI::Command
            if ENV["GLI_DEBUG"] == 'true'
              $stderr.puts "Using '#{name}' as it's is short for #{found_match.name}."
              $stderr.puts "Set autocomplete false for any command you don't want matched like this"
            end
          elsif found_match.kind_of?(Array) && !found_match.empty?
            raise AmbiguousCommand.new("Ambiguous command '#{name}'. It matches #{found_match.sort.join(',')}")
          end
          found_match
        end
      end

      raise UnknownCommand.new("Unknown command '#{name}'") if Array(command_found).empty?
      command_found
    end

  private
    attr_accessor :commands_with_aliases

    def expand_with_aliases(commands)
      expanded = {}
      commands.each do |command_name, command|
        expanded[command_name.to_s] = command
        Array(command.aliases).each do |command_alias|
          expanded[command_alias.to_s] = command
        end
      end
      expanded
    end

    def find_command_by_partial_name(commands_with_aliases, command_to_match)
      partial_matches = commands_with_aliases.keys.select { |command_name| command_name =~ /^#{command_to_match}/ }
      return commands_with_aliases[partial_matches[0]] if partial_matches.size == 1
      partial_matches
    end
  end
end
