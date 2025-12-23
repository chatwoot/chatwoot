#
# Copyright (c) 2013-2022 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# bundler-audit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bundler-audit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bundler-audit.  If not, see <https://www.gnu.org/licenses/>.
#

require 'thor'

module Bundler
  module Audit
    class CLI < ::Thor
      #
      # {Bundler::Audit::CLI} supports outputting it's audit results as
      # {Bundler::Audit::CLI::Formats::Text text} or
      # {Bundler::Audit::CLI::Formats::JSON JSON}, by default.
      #
      # ## API
      #
      # {Bundler::Audit::CLI} formats are really just modules defined under
      # {Bundler::Audit::CLI::Formats}, that define a `#print_report` entry
      # method. When the `#print_report` method is called it will be passed a
      # {Bundler::Audit::Report report} object and an optional `output`
      # stream, which may be either `$stdout` or a `File` object.
      #
      # {Bundler::Audit::CLI} will load a format by first calling
      # {Formats.load}, which attempts to require the
      # `bundler/audit/cli/formats/#{format}.rb` file, then gets the registered
      # format module using {Formats.[]}.
      # If the format module has been successfully loaded, it will be extended
      # into the {Bundler::Audit::CLI} instance method access to
      # {Bundler::Audit::CLI}'s instance methods.
      #
      # ## Custom Formats
      #
      # To define a custom format, it...
      #
      # * MUST be defined in a file in a
      # `lib/bundler/audit/cli/formats/` directory.
      # * MUST define a `print_report(report,output=$stdout)` instance method.
      # * MUST register themselves by calling {Formats.register} at the end
      #   of the file.
      #
      # ### Example
      #
      #     # lib/bundler/audit/cli/formats/my_format.rb
      #     module Bundler
      #       module Audit
      #         class CLI < ::Thor
      #           module Formats
      #             module MyFormat
      #               def print_report(report,output=$stdout)
      #                 # ...
      #               end
      #             end
      #
      #             Formats.register :my_format, MyFormat
      #           end
      #         end
      #       end
      #     end
      #
      module Formats
        class FormatNotFound < RuntimeError
        end

        # Directory where format modules are loaded from.
        DIR = 'bundler/audit/cli/formats'

        @registry = {}

        #
        # Registers a format with the given format name.
        #
        # @param [Symbol, String] name
        #
        # @param [Module#print_results] format
        #   The format object.
        #
        # @raise [NotImplementedError]
        #   The format object does not respond to `#call`.
        #
        # @api public
        #
        def self.register(name,format)
          unless format.instance_methods.include?(:print_report)
            raise(NotImplementedError,"#{format.inspect} does not define #print_report")
          end

          @registry[name.to_sym] = format
        end

        #
        # Retrieves the format by name.
        #
        # @param [String, Symbol] name
        #
        # @return [Module#print_results, nil]
        #   The format registered with the given name or `nil`.
        #
        def self.[](name)
          @registry[name.to_sym]
        end

        #
        # Loads the format with the given name by attempting to require
        # `bundler/audit/cli/formats/#{name}` and returning the registered
        # format using {[]}.
        #
        # @param [#to_s] name
        #
        # @return [Module#print_results]
        #
        # @raise [FormatNotFound]
        #   No format exists with that given name.
        #
        def self.load(name)
          name = name.to_s
          path = File.join(DIR,File.basename(name))

          begin
            require path
          rescue LoadError
            raise(FormatNotFound,"could not load format #{name.inspect}")
          end

          unless (format = self[name])
            raise(FormatNotFound,"unknown format #{name.inspect}")
          end

          return  format
        end
      end
    end
  end
end

require 'bundler/audit/cli/formats/text'
