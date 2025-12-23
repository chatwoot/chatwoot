# frozen_string_literal: true

class Pry
  class Command
    class Edit
      module FileAndLineLocator
        class << self
          def from_binding(target)
            if target.respond_to?(:source_location)
              target.source_location
            else
              target.eval("[__FILE__, __LINE__]")
            end
          end

          def from_code_object(code_object, filename_argument)
            unless File.exist?(code_object.source_file.to_s)
              raise CommandError, "Cannot find a file for #{filename_argument}!"
            end

            [code_object.source_file, code_object.source_line]
          end

          def from_exception(exception, backtrace_level)
            raise CommandError, "No exception found." if exception.nil?

            file_name, line = exception.bt_source_location_for(backtrace_level)
            raise CommandError, "Exception has no associated file." if file_name.nil?

            if Pry.eval_path == file_name
              raise CommandError, "Cannot edit exceptions raised in REPL."
            end

            [file_name, line]
          end

          # when file and line are passed as a single arg, e.g my_file.rb:30
          def from_filename_argument(filename_argument)
            f = File.expand_path(filename_argument)
            l = f.sub!(/:(\d+)$/, "") ? Regexp.last_match(1).to_i : 1
            [f, l]
          end
        end
      end
    end
  end
end
