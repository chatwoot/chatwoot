require "spring/configuration"

module Spring
  class CommandWrapper
    attr_reader :name, :command

    def initialize(name, command = nil)
      @name    = name
      @command = command
      @setup   = false
    end

    def description
      if command.respond_to?(:description)
        command.description
      else
        "Runs the #{name} command"
      end
    end

    def setup?
      @setup
    end

    def setup
      if !setup? && command.respond_to?(:setup)
        command.setup
        @setup = true
        return true
      else
        @setup = true
        return false
      end
    end

    def call
      if command.respond_to?(:call)
        command.call
      else
        load exec
      end
    end

    def gem_name
      if command.respond_to?(:gem_name)
        command.gem_name
      else
        exec_name
      end
    end

    def exec_name
      if command.respond_to?(:exec_name)
        command.exec_name
      else
        name
      end
    end

    def binstub
      Spring.application_root_path.join(binstub_name)
    end

    def binstub_name
      "bin/#{name}"
    end

    def exec
      if binstub.exist?
        binstub.to_s
      else
        Gem.bin_path(gem_name, exec_name)
      end
    end

    def env(args)
      if command.respond_to?(:env)
        command.env(args)
      end
    end
  end
end
