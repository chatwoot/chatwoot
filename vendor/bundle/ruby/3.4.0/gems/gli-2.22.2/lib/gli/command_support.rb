module GLI
  # Things unrelated to the true public interface of Command that are needed for bookkeeping
  # and help support.  Generally, you shouldn't be calling these methods; they are technically public
  # but are essentially part of GLI's internal implementation and subject to change
  module CommandSupport
    # The parent of this command, either the GLI app, or another command
    attr_accessor :parent

    def context_description
      "in the command #{name}"
    end

    # Return true to avoid including this command in your help strings
    # Will honor the hide_commands_without_desc flag
    def nodoc
      @hide_commands_without_desc and description.nil?
    end

    # Return the arguments description
    def arguments_description 
      @arguments_description
    end

    def arguments_options
      @arguments_options
    end

    def arguments
      @arguments
    end

    # If true, this command doesn't want the pre block run before it executes
    def skips_pre 
      @skips_pre
    end

    # If true, this command doesn't want the post block run before it executes
    def skips_post 
      @skips_post
    end

    # If true, this command doesn't want the around block called
    def skips_around
      @skips_around
    end

    # Return the Array of the command's names
    def names 
      all_forms
    end

    # Returns the array of examples
    def examples
      @examples
    end

    # Get an array of commands, ordered by when they were declared
    def commands_declaration_order # :nodoc:
      @commands_declaration_order
    end

    def flag(*names)
      if send_declarations_to_parent?
        new_flag = if parent.kind_of? Command
                     super(*names)
                     parent.flag(*names)
                   else
                     super(*names)
                   end
        new_flag.associated_command = self
        new_flag
      else
        super(*names)
      end
    end

    def switch(*names)
      if send_declarations_to_parent?
        new_switch = if parent.kind_of? Command
                       super(*names)
                       parent.switch(*names)
                     else
                       super(*names)
                     end
        new_switch.associated_command = self
        new_switch
      else
        super(*names)
      end
    end

    def desc(d)
      parent.desc(d) if parent.kind_of?(Command) && send_declarations_to_parent?
      super(d)
    end

    def long_desc(d)
      parent.long_desc(d) if parent.kind_of?(Command) && send_declarations_to_parent?
      super(d)
    end

    def arg_name(d,options=[])
      parent.arg_name(d,options) if parent.kind_of?(Command) && send_declarations_to_parent?
      super(d,options)
    end

    def default_value(d)
      parent.default_value(d) if parent.kind_of?(Command) && send_declarations_to_parent?
      super(d)
    end

    # Return the flags as a Hash
    def flags 
      @flags ||= {}
    end
    # Return the switches as a Hash
    def switches 
      @switches ||= {}
    end

    def commands # :nodoc:
      @commands ||= {}
    end

    def default_description
      @default_desc
    end

    # Executes the command
    def execute(global_options,options,arguments)
      get_action(arguments).call(global_options,options,arguments)
    end

    def topmost_ancestor
      some_command = self
      top = some_command
      while some_command.kind_of? self.class
        top = some_command
        some_command = some_command.parent
      end
      top
    end

    def has_action?
      !!@action
    end

    def get_default_command
      @default_command
    end

  private

    def send_declarations_to_parent?
      app = topmost_ancestor.parent
      app.nil? ? true : (app.subcommand_option_handling_strategy == :legacy)
    end

    def get_action(arguments)
      if @action
        @action
      else
        generate_error_action(arguments)
      end
    end

    def generate_error_action(arguments)
      lambda { |global_options,options,arguments|
        if am_subcommand? && arguments.size > 0
          raise UnknownCommand,"Unknown command '#{arguments[0]}'"
        elsif have_subcommands?
          raise BadCommandLine,"Command '#{name}' requires a subcommand #{self.commands.keys.join(',')}"
        else
          raise "Command '#{name}' has no action block"
        end
      }
    end

    def am_subcommand?
      parent.kind_of?(Command)
    end

    def have_subcommands?
      !self.commands.empty?
    end
  end
end
