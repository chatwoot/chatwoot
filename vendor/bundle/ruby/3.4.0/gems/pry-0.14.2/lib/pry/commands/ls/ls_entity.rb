# frozen_string_literal: true

class Pry
  class Command
    class Ls < Pry::ClassCommand
      class LsEntity
        attr_reader :pry_instance

        def initialize(opts)
          @interrogatee = opts[:interrogatee]
          @no_user_opts = opts[:no_user_opts]
          @opts = opts[:opts]
          @args = opts[:args]
          @grep = Grep.new(Regexp.new(opts[:opts][:G] || '.'))
          @pry_instance = opts.delete(:pry_instance)
        end

        def entities_table
          entities.map(&:write_out).select { |o| o }.join('')
        end

        private

        def grep(entity)
          entity.tap { |o| o.grep = @grep }
        end

        def globals
          grep Globals.new(@opts, pry_instance)
        end

        def constants
          grep Constants.new(@interrogatee, @no_user_opts, @opts, pry_instance)
        end

        def methods
          grep(Methods.new(@interrogatee, @no_user_opts, @opts, pry_instance))
        end

        def self_methods
          grep SelfMethods.new(@interrogatee, @no_user_opts, @opts, pry_instance)
        end

        def instance_vars
          grep InstanceVars.new(@interrogatee, @no_user_opts, @opts, pry_instance)
        end

        def local_names
          grep LocalNames.new(@no_user_opts, @args, pry_instance)
        end

        def local_vars
          LocalVars.new(@opts, pry_instance)
        end

        def entities
          [
            globals, constants, methods, self_methods, instance_vars, local_names,
            local_vars
          ]
        end
      end
    end
  end
end
