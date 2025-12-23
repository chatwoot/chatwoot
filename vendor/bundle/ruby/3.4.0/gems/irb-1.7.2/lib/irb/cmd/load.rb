# frozen_string_literal: false
#
#   load.rb -
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

require_relative "nop"
require_relative "../ext/loader"

module IRB
  # :stopdoc:

  module ExtendCommand
    class LoaderCommand < Nop
      include IrbLoader

      def raise_cmd_argument_error
        raise CommandArgumentError.new("Please specify the file name.")
      end
    end

    class Load < LoaderCommand
      category "IRB"
      description "Load a Ruby file."

      def execute(file_name = nil, priv = nil)
        raise_cmd_argument_error unless file_name
        irb_load(file_name, priv)
      end
    end

    class Require < LoaderCommand
      category "IRB"
      description "Require a Ruby file."
      def execute(file_name = nil)
        raise_cmd_argument_error unless file_name

        rex = Regexp.new("#{Regexp.quote(file_name)}(\.o|\.rb)?")
        return false if $".find{|f| f =~ rex}

        case file_name
        when /\.rb$/
          begin
            if irb_load(file_name)
              $".push file_name
              return true
            end
          rescue LoadError
          end
        when /\.(so|o|sl)$/
          return ruby_require(file_name)
        end

        begin
          irb_load(f = file_name + ".rb")
          $".push f
          return true
        rescue LoadError
          return ruby_require(file_name)
        end
      end
    end

    class Source < LoaderCommand
      category "IRB"
      description "Loads a given file in the current session."

      def execute(file_name = nil)
        raise_cmd_argument_error unless file_name

        source_file(file_name)
      end
    end
  end
  # :startdoc:
end
