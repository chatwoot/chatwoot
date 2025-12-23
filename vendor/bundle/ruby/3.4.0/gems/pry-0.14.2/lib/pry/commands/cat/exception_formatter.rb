# frozen_string_literal: true

class Pry
  class Command
    class Cat
      class ExceptionFormatter < AbstractFormatter
        attr_reader :ex
        attr_reader :opts
        attr_reader :pry_instance
        include Pry::Helpers::Text

        def initialize(exception, pry_instance, opts)
          @ex = exception
          @opts = opts
          @pry_instance = pry_instance
        end

        def format
          check_for_errors
          set_file_and_dir_locals(
            backtrace_file, pry_instance, pry_instance.current_context
          )
          code = decorate(
            Pry::Code.from_file(backtrace_file)
              .between(*start_and_end_line_for_code_window)
              .with_marker(backtrace_line)
          )
          "#{header}#{code}"
        end

        private

        def code_window_size
          pry_instance.config.default_window_size || 5
        end

        def backtrace_level
          @backtrace_level ||=
            begin
              bl =
                if opts[:ex].nil?
                  ex.bt_index
                else
                  ex.bt_index = absolute_index_number(opts[:ex], ex.backtrace.size)
                end

              increment_backtrace_level
              bl
            end
        end

        def increment_backtrace_level
          ex.inc_bt_index
        end

        def backtrace_file
          Array(ex.bt_source_location_for(backtrace_level)).first
        end

        def backtrace_line
          Array(ex.bt_source_location_for(backtrace_level)).last
        end

        def check_for_errors
          raise CommandError, "No exception found." unless ex
          return if backtrace_file

          raise CommandError, "The given backtrace level is out of bounds."
        end

        def start_and_end_line_for_code_window
          start_line = backtrace_line - code_window_size
          start_line = 1 if start_line < 1

          [start_line, backtrace_line + code_window_size]
        end

        def header
          unindent(
            "#{bold 'Exception:'} #{ex.class}: #{ex.message}\n" \
            "--\n" \
            "#{bold('From:')} #{backtrace_file}:#{backtrace_line} @ " \
            "#{bold("level: #{backtrace_level}")} of backtrace " \
            "(of #{ex.backtrace.size - 1}).\n\n"
          )
        end
      end
    end
  end
end
