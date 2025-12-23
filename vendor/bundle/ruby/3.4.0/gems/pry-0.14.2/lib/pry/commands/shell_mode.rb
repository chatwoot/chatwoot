# frozen_string_literal: true

class Pry
  class Command
    class ShellMode < Pry::ClassCommand
      match 'shell-mode'
      group 'Input and Output'
      description 'Toggle shell mode. Bring in pwd prompt and file completion.'

      banner <<-'BANNER'
        Toggle shell mode. Bring in pwd prompt and file completion.
      BANNER

      def process
        state.disabled ^= true

        if state.disabled
          state.prev_prompt = pry_instance.prompt
          pry_instance.prompt = Pry::Prompt[:shell]
        else
          pry_instance.prompt = state.prev_prompt
        end
      end
    end

    Pry::Commands.add_command(Pry::Command::ShellMode)
    Pry::Commands.alias_command 'file-mode', 'shell-mode'
  end
end
