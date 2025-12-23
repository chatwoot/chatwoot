module GLI
  module Commands
    module HelpModules
      # Handles wrapping text
      class ArgNameFormatter
        def format(arguments_description,arguments_options,arguments)
          # Select which format to use: argname or arguments
          # Priority to old way: argname
          desc = format_argname(arguments_description, arguments_options)
          desc = format_arguments(arguments) if desc.strip == ''
          desc
        end

        def format_arguments(arguments)
          return '' if arguments.empty?
          desc = ""

          # Go through the arguments, building the description string
          arguments.each do |arg|
            arg_desc = "#{arg.name}"
            if arg.optional?
              arg_desc = "[#{arg_desc}]"
            end
            if arg.multiple?
              arg_desc = "#{arg_desc}..."
            end
            desc = desc + " " + arg_desc
          end

          desc
        end

        def format_argname(arguments_description,arguments_options)
          return '' if String(arguments_description).strip == ''
          desc = arguments_description
          if arguments_options.include? :optional
            desc = "[#{desc}]"
          end
          if arguments_options.include? :multiple
            desc = "#{desc}..."
          end
          " " + desc
        end
      end
    end
  end
end
