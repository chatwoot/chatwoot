# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Shows the given cops, or all cops by default, and their configurations
      # for the current directory.
      # @api private
      class ShowCops < Base
        self.command_name = :show_cops

        ExactMatcher = Struct.new(:pattern) do
          def match?(name)
            name == pattern
          end
        end

        WildcardMatcher = Struct.new(:pattern) do
          def match?(name)
            File.fnmatch(pattern, name, File::FNM_PATHNAME)
          end
        end

        def initialize(env)
          super

          # Load the configs so the require()s are done for custom cops
          @config = @config_store.for(Dir.pwd)

          @cop_matchers = @options[:show_cops].map do |pattern|
            if pattern.include?('*')
              WildcardMatcher.new(pattern)
            else
              ExactMatcher.new(pattern)
            end
          end
        end

        def run
          print_available_cops
        end

        private

        def print_available_cops
          registry = Cop::Registry.global
          show_all = @cop_matchers.empty?

          puts "# Available cops (#{registry.length}) + config for #{Dir.pwd}: " if show_all

          registry.departments.sort!.each do |department|
            print_cops_of_department(registry, department, show_all)
          end
        end

        def print_cops_of_department(registry, department, show_all)
          selected_cops = if show_all
                            cops_of_department(registry, department)
                          else
                            selected_cops_of_department(registry, department)
                          end

          puts "# Department '#{department}' (#{selected_cops.length}):" if show_all

          print_cop_details(selected_cops)
        end

        def print_cop_details(cops)
          cops.each do |cop|
            puts '# Supports --autocorrect' if cop.support_autocorrect?
            puts "#{cop.cop_name}:"
            puts config_lines(cop)
            puts
          end
        end

        def selected_cops_of_department(cops, department)
          cops_of_department(cops, department).select do |cop|
            @cop_matchers.any? do |matcher|
              matcher.match?(cop.cop_name)
            end
          end
        end

        def cops_of_department(cops, department)
          cops.with_department(department).sort!
        end

        def config_lines(cop)
          cnf = @config.for_cop(cop)
          cnf.to_yaml.lines.to_a.drop(1).map { |line| "  #{line}" }
        end
      end
    end
  end
end
