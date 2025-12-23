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

require 'bundler/audit/scanner'
require 'bundler/audit/version'
require 'bundler/audit/cli/formats'

require 'thor'
require 'bundler/audit/cli/thor_ext/shell/basic/say_error'
require 'bundler'

module Bundler
  module Audit
    #
    # The `bundle-audit` command.
    #
    class CLI < ::Thor

      default_task :check
      map '--version' => :version

      desc 'check [DIR]', 'Checks the Gemfile.lock for insecure dependencies'
      method_option :quiet, type: :boolean, aliases: '-q'
      method_option :verbose, type: :boolean, aliases: '-v'
      method_option :ignore, type: :array, aliases: '-i'
      method_option :update, type: :boolean, aliases: '-u'
      method_option :database, type: :string, aliases: '-D',
                               default: Database::USER_PATH
      method_option :format, type: :string, default: 'text', aliases: '-F'
      method_option :config, type: :string, aliases: '-c', default: '.bundler-audit.yml'
      method_option :gemfile_lock, type: :string, aliases: '-G',
                                   default: 'Gemfile.lock'
      method_option :output, type: :string, aliases: '-o'

      def check(dir=Dir.pwd)
        unless File.directory?(dir)
          say_error "No such file or directory: #{dir}", :red
          exit 1
        end

        begin
          extend Formats.load(options[:format])
        rescue Formats::FormatNotFound
          say_error "Unknown format: #{options[:format]}", :red
          exit 1
        end

        if !Database.exists?(options[:database])
          download(options[:database])
        elsif options[:update]
          update(options[:database])
        end

        database = Database.new(options[:database])
        scanner  = begin
                     Scanner.new(dir,options[:gemfile_lock],database, options[:config])
                   rescue Bundler::GemfileLockNotFound => exception
                     say exception.message, :red
                     exit 1
                   end

        report = scanner.report(ignore: options.ignore)

        output = if options[:output]
                   File.new(options[:output],'w')
                 else
                   $stdout
                 end

        print_report(report,output)

        output.close if options[:output]

        exit(1) if report.vulnerable?
      end

      desc 'stats', 'Prints ruby-advisory-db stats'
      method_option :quiet, type: :boolean, aliases: '-q'

      def stats(path=Database.path)
        database = Database.new(path)

        puts "ruby-advisory-db:"
        puts "  advisories:\t#{database.size} advisories"
        puts "  last updated:\t#{database.last_updated_at}"

        if (commit_id = database.commit_id)
          puts "  commit:\t#{commit_id}"
        end
      end

      desc 'download', 'Downloads ruby-advisory-db'
      method_option :quiet, type: :boolean, aliases: '-q'

      def download(path=Database.path)
        if Database.exists?(path)
          say "Database already exists", :yellow
          return
        end

        say("Download ruby-advisory-db ...") unless options.quiet?

        begin
          Database.download(path: path, quiet: options.quiet?)
        rescue Database::DownloadFailed => error
          say error.message, :red
          exit 1
        end

        stats(path) unless options.quiet?
      end

      desc 'update', 'Updates the ruby-advisory-db'
      method_option :quiet, type: :boolean, aliases: '-q'

      def update(path=Database.path)
        unless Database.exists?(path)
          download(path)
          return
        end

        say("Updating ruby-advisory-db ...") unless options.quiet?

        database = Database.new(path)

        case database.update!(quiet: options.quiet?)
        when true
          say("Updated ruby-advisory-db", :green) unless options.quiet?
        when false
          say_error "Failed updating ruby-advisory-db!", :red
          exit 1
        when nil
          unless Bundler.git_present?
            say_error "Git is not installed!", :red
            exit 1
          end

          say "Skipping update", :yellow
        end

        stats(path) unless options.quiet?
      end

      desc 'version', 'Prints the bundler-audit version'
      def version
        puts "bundler-audit #{VERSION}"
      end

      protected

      #
      # @note Silence deprecation warnings from Thor.
      #
      def self.exit_on_failure?
        true
      end

      #
      # @abstract
      #
      def print_report(report)
        raise(NotImplementedError,"#{self.class}##{__method__} not defined")
      end

    end
  end
end
