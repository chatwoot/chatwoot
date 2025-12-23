require 'shellwords'
require_relative "nop"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Edit < Nop
      category "Misc"
      description 'Open a file with the editor command defined with `ENV["EDITOR"]`.'

      class << self
        def transform_args(args)
          # Return a string literal as is for backward compatibility
          if args.nil? || args.empty? || string_literal?(args)
            args
          else # Otherwise, consider the input as a String for convenience
            args.strip.dump
          end
        end
      end

      def execute(*args)
        path = args.first

        if path.nil? && (irb_path = @irb_context.irb_path)
          path = irb_path
        end

        if !File.exist?(path)
          require_relative "show_source"

          source =
            begin
              ShowSource.find_source(path, @irb_context)
            rescue NameError
              # if user enters a path that doesn't exist, it'll cause NameError when passed here because find_source would try to evaluate it as well
              # in this case, we should just ignore the error
            end

          if source && File.exist?(source.file)
            path = source.file
          else
            puts "Can not find file: #{path}"
            return
          end
        end

        if editor = ENV['EDITOR']
          puts "command: '#{editor}'"
          puts "   path: #{path}"
          system(*Shellwords.split(editor), path)
        else
          puts "Can not find editor setting: ENV['EDITOR']"
        end
      end
    end
  end

  # :startdoc:
end
