# frozen_string_literal: true

class Pry
  class Command
    class Edit
      class ExceptionPatcher
        attr_accessor :pry_instance
        attr_accessor :state
        attr_accessor :file_and_line

        def initialize(pry_instance, state, exception_file_and_line)
          @pry_instance = pry_instance
          @state = state
          @file_and_line = exception_file_and_line
        end

        # perform the patch
        def perform_patch
          file_name, = file_and_line
          lines = state.dynamical_ex_file || File.read(file_name)

          source = Pry::Editor.new(pry_instance).edit_tempfile_with_content(lines)
          pry_instance.evaluate_ruby source
          state.dynamical_ex_file = source.split("\n")
        end
      end
    end
  end
end
