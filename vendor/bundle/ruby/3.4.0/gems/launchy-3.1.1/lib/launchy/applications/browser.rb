# frozen_string_literal: true

module Launchy
  class Application
    #
    # The class handling the browser application and all of its schemes
    #
    class Browser < Launchy::Application
      def self.schemes
        %w[http https ftp file]
      end

      def self.handles?(uri)
        return true if schemes.include?(uri.scheme)

        true if File.exist?(uri.path)
      end

      # The escaped \\ is necessary so that when shellsplit is done later,
      # the "launchy", with quotes, goes through to the commandline, since that
      def windows_app_list
        ['start \\"launchy\\" /b']
      end

      def cygwin_app_list
        ['cmd /C start \\"launchy\\" /b']
      end

      # hardcode this to open?
      def darwin_app_list
        [find_executable("open")]
      end

      def nix_app_list
        nix_de = Launchy::Detect::NixDesktopEnvironment.detect
        list   = nix_de.browsers
        list.find_all(&:valid?)
      end

      # use a call back mechanism to get the right app_list that is decided by the
      # host_os_family class.
      def app_list
        host_os_family.app_list(self)
      end

      def browser_env
        return [] unless ENV["BROWSER"]

        browser_env = ENV["BROWSER"].split(File::PATH_SEPARATOR)
        browser_env.flatten!
        browser_env.delete_if { |b| b.nil? || b.strip.empty? }
        browser_env
      end

      # Get the full commandline of what we are going to add the uri to
      def browser_cmdline
        browser_env.each do |p|
          Launchy.log "#{self.class.name} : possibility from BROWSER environment variable : #{p}"
        end
        app_list.each do |p|
          Launchy.log "#{self.class.name} : possibility from app_list : #{p}"
        end

        possibilities = (browser_env + app_list).flatten

        if (browser = possibilities.shift)
          Launchy.log "#{self.class.name} : Using browser value '#{browser}'"
          return browser
        end
        raise Launchy::CommandNotFoundError,
              "Unable to find a browser command. If this is unexpected, #{Launchy.bug_report_message}"
      end

      def cmd_and_args(uri, _options = {})
        cmd = browser_cmdline.to_s
        args = [uri.to_s]
        cmd.gsub!("%s", args.shift) if cmd.include?("%s")
        [cmd, args]
      end

      # final assembly of the command and do %s substitution
      # http://www.catb.org/~esr/BROWSER/index.html
      def open(uri, options = {})
        cmd, args = cmd_and_args(uri, options)
        run(cmd, args)
      end
    end
  end
end
