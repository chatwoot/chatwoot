# frozen_string_literal: false
#
#   irb/extend-command.rb - irb extend command
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

module IRB # :nodoc:
  # Installs the default irb extensions command bundle.
  module ExtendCommandBundle
    EXCB = ExtendCommandBundle # :nodoc:

    # See #install_alias_method.
    NO_OVERRIDE = 0
    # See #install_alias_method.
    OVERRIDE_PRIVATE_ONLY = 0x01
    # See #install_alias_method.
    OVERRIDE_ALL = 0x02

    # Quits the current irb context
    #
    # +ret+ is the optional signal or message to send to Context#exit
    #
    # Same as <code>IRB.CurrentContext.exit</code>.
    def irb_exit(ret = 0)
      irb_context.exit(ret)
    end

    # Displays current configuration.
    #
    # Modifying the configuration is achieved by sending a message to IRB.conf.
    def irb_context
      IRB.CurrentContext
    end

    @ALIASES = [
      [:context, :irb_context, NO_OVERRIDE],
      [:conf, :irb_context, NO_OVERRIDE],
      [:irb_quit, :irb_exit, OVERRIDE_PRIVATE_ONLY],
      [:exit, :irb_exit, OVERRIDE_PRIVATE_ONLY],
      [:quit, :irb_exit, OVERRIDE_PRIVATE_ONLY],
    ]


    @EXTEND_COMMANDS = [
      [
        :irb_current_working_workspace, :CurrentWorkingWorkspace, "cmd/chws",
        [:cwws, NO_OVERRIDE],
        [:pwws, NO_OVERRIDE],
        [:irb_print_working_workspace, OVERRIDE_ALL],
        [:irb_cwws, OVERRIDE_ALL],
        [:irb_pwws, OVERRIDE_ALL],
        [:irb_current_working_binding, OVERRIDE_ALL],
        [:irb_print_working_binding, OVERRIDE_ALL],
        [:irb_cwb, OVERRIDE_ALL],
        [:irb_pwb, OVERRIDE_ALL],
      ],
      [
        :irb_change_workspace, :ChangeWorkspace, "cmd/chws",
        [:chws, NO_OVERRIDE],
        [:cws, NO_OVERRIDE],
        [:irb_chws, OVERRIDE_ALL],
        [:irb_cws, OVERRIDE_ALL],
        [:irb_change_binding, OVERRIDE_ALL],
        [:irb_cb, OVERRIDE_ALL],
        [:cb, NO_OVERRIDE],
      ],

      [
        :irb_workspaces, :Workspaces, "cmd/pushws",
        [:workspaces, NO_OVERRIDE],
        [:irb_bindings, OVERRIDE_ALL],
        [:bindings, NO_OVERRIDE],
      ],
      [
        :irb_push_workspace, :PushWorkspace, "cmd/pushws",
        [:pushws, NO_OVERRIDE],
        [:irb_pushws, OVERRIDE_ALL],
        [:irb_push_binding, OVERRIDE_ALL],
        [:irb_pushb, OVERRIDE_ALL],
        [:pushb, NO_OVERRIDE],
      ],
      [
        :irb_pop_workspace, :PopWorkspace, "cmd/pushws",
        [:popws, NO_OVERRIDE],
        [:irb_popws, OVERRIDE_ALL],
        [:irb_pop_binding, OVERRIDE_ALL],
        [:irb_popb, OVERRIDE_ALL],
        [:popb, NO_OVERRIDE],
      ],

      [
        :irb_load, :Load, "cmd/load"],
      [
        :irb_require, :Require, "cmd/load"],
      [
        :irb_source, :Source, "cmd/load",
        [:source, NO_OVERRIDE],
      ],

      [
        :irb, :IrbCommand, "cmd/subirb"],
      [
        :irb_jobs, :Jobs, "cmd/subirb",
        [:jobs, NO_OVERRIDE],
      ],
      [
        :irb_fg, :Foreground, "cmd/subirb",
        [:fg, NO_OVERRIDE],
      ],
      [
        :irb_kill, :Kill, "cmd/subirb",
        [:kill, OVERRIDE_PRIVATE_ONLY],
      ],

      [
        :irb_debug, :Debug, "cmd/debug",
        [:debug, NO_OVERRIDE],
      ],
      [
        :irb_edit, :Edit, "cmd/edit",
        [:edit, NO_OVERRIDE],
      ],
      [
        :irb_break, :Break, "cmd/break",
      ],
      [
        :irb_catch, :Catch, "cmd/catch",
      ],
      [
        :irb_next, :Next, "cmd/next"
      ],
      [
        :irb_delete, :Delete, "cmd/delete",
        [:delete, NO_OVERRIDE],
      ],
      [
        :irb_step, :Step, "cmd/step",
        [:step, NO_OVERRIDE],
      ],
      [
        :irb_continue, :Continue, "cmd/continue",
        [:continue, NO_OVERRIDE],
      ],
      [
        :irb_finish, :Finish, "cmd/finish",
        [:finish, NO_OVERRIDE],
      ],
      [
        :irb_backtrace, :Backtrace, "cmd/backtrace",
        [:backtrace, NO_OVERRIDE],
        [:bt, NO_OVERRIDE],
      ],
      [
        :irb_debug_info, :Info, "cmd/info",
        [:info, NO_OVERRIDE],
      ],

      [
        :irb_help, :Help, "cmd/help",
        [:help, NO_OVERRIDE],
      ],

      [
        :irb_show_doc, :ShowDoc, "cmd/show_doc",
        [:show_doc, NO_OVERRIDE],
      ],

      [
        :irb_info, :IrbInfo, "cmd/irb_info"
      ],

      [
        :irb_ls, :Ls, "cmd/ls",
        [:ls, NO_OVERRIDE],
      ],

      [
        :irb_measure, :Measure, "cmd/measure",
        [:measure, NO_OVERRIDE],
      ],

      [
        :irb_show_source, :ShowSource, "cmd/show_source",
        [:show_source, NO_OVERRIDE],
      ],

      [
        :irb_whereami, :Whereami, "cmd/whereami",
        [:whereami, NO_OVERRIDE],
      ],
      [
        :irb_show_cmds, :ShowCmds, "cmd/show_cmds",
        [:show_cmds, NO_OVERRIDE],
      ]
    ]


    @@commands = []

    def self.all_commands_info
      return @@commands unless @@commands.empty?
      user_aliases = IRB.CurrentContext.command_aliases.each_with_object({}) do |(alias_name, target), result|
        result[target] ||= []
        result[target] << alias_name
      end

      @EXTEND_COMMANDS.each do |cmd_name, cmd_class, load_file, *aliases|
        if !defined?(ExtendCommand) || !ExtendCommand.const_defined?(cmd_class, false)
          require_relative load_file
        end

        klass = ExtendCommand.const_get(cmd_class, false)
        aliases = aliases.map { |a| a.first }

        if additional_aliases = user_aliases[cmd_name]
          aliases += additional_aliases
        end

        display_name = aliases.shift || cmd_name
        @@commands << { display_name: display_name, description: klass.description, category: klass.category }
      end

      @@commands
    end

    # Convert a command name to its implementation class if such command exists
    def self.load_command(command)
      command = command.to_sym
      @EXTEND_COMMANDS.each do |cmd_name, cmd_class, load_file, *aliases|
        next if cmd_name != command && aliases.all? { |alias_name, _| alias_name != command }

        if !defined?(ExtendCommand) || !ExtendCommand.const_defined?(cmd_class, false)
          require_relative load_file
        end
        return ExtendCommand.const_get(cmd_class, false)
      end
      nil
    end

    # Installs the default irb commands.
    def self.install_extend_commands
      for args in @EXTEND_COMMANDS
        def_extend_command(*args)
      end
    end

    # Evaluate the given +cmd_name+ on the given +cmd_class+ Class.
    #
    # Will also define any given +aliases+ for the method.
    #
    # The optional +load_file+ parameter will be required within the method
    # definition.
    def self.def_extend_command(cmd_name, cmd_class, load_file, *aliases)
      case cmd_class
      when Symbol
        cmd_class = cmd_class.id2name
      when String
      when Class
        cmd_class = cmd_class.name
      end

      line = __LINE__; eval %[
        def #{cmd_name}(*opts, **kwargs, &b)
          Kernel.require_relative "#{load_file}"
          ::IRB::ExtendCommand::#{cmd_class}.execute(irb_context, *opts, **kwargs, &b)
        end
      ], nil, __FILE__, line

      for ali, flag in aliases
        @ALIASES.push [ali, cmd_name, flag]
      end
    end

    # Installs alias methods for the default irb commands, see
    # ::install_extend_commands.
    def install_alias_method(to, from, override = NO_OVERRIDE)
      to = to.id2name unless to.kind_of?(String)
      from = from.id2name unless from.kind_of?(String)

      if override == OVERRIDE_ALL or
          (override == OVERRIDE_PRIVATE_ONLY) && !respond_to?(to) or
          (override == NO_OVERRIDE) &&  !respond_to?(to, true)
        target = self
        (class << self; self; end).instance_eval{
          if target.respond_to?(to, true) &&
            !target.respond_to?(EXCB.irb_original_method_name(to), true)
            alias_method(EXCB.irb_original_method_name(to), to)
          end
          alias_method to, from
        }
      else
        Kernel.warn "irb: warn: can't alias #{to} from #{from}.\n"
      end
    end

    def self.irb_original_method_name(method_name) # :nodoc:
      "irb_" + method_name + "_org"
    end

    # Installs alias methods for the default irb commands on the given object
    # using #install_alias_method.
    def self.extend_object(obj)
      unless (class << obj; ancestors; end).include?(EXCB)
        super
        for ali, com, flg in @ALIASES
          obj.install_alias_method(ali, com, flg)
        end
      end
    end

    install_extend_commands
  end

  # Extends methods for the Context module
  module ContextExtender
    CE = ContextExtender # :nodoc:

    @EXTEND_COMMANDS = [
      [:eval_history=, "ext/eval_history.rb"],
      [:use_tracer=, "ext/tracer.rb"],
      [:use_loader=, "ext/use-loader.rb"],
    ]

    # Installs the default context extensions as irb commands:
    #
    # Context#eval_history=::   +irb/ext/history.rb+
    # Context#use_tracer=::     +irb/ext/tracer.rb+
    # Context#use_loader=::     +irb/ext/use-loader.rb+
    def self.install_extend_commands
      for args in @EXTEND_COMMANDS
        def_extend_command(*args)
      end
    end

    # Evaluate the given +command+ from the given +load_file+ on the Context
    # module.
    #
    # Will also define any given +aliases+ for the method.
    def self.def_extend_command(cmd_name, load_file, *aliases)
      line = __LINE__; Context.module_eval %[
        def #{cmd_name}(*opts, &b)
          Context.module_eval {remove_method(:#{cmd_name})}
          require_relative "#{load_file}"
          __send__ :#{cmd_name}, *opts, &b
        end
        for ali in aliases
          alias_method ali, cmd_name
        end
      ], __FILE__, line
    end

    CE.install_extend_commands
  end
end
