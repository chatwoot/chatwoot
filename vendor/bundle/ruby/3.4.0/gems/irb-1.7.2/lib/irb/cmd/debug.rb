require_relative "nop"

module IRB
  # :stopdoc:

  module ExtendCommand
    class Debug < Nop
      category "Debugging"
      description "Start the debugger of debug.gem."

      BINDING_IRB_FRAME_REGEXPS = [
        '<internal:prelude>',
        binding.method(:irb).source_location.first,
      ].map { |file| /\A#{Regexp.escape(file)}:\d+:in `irb'\z/ }
      IRB_DIR = File.expand_path('..', __dir__)

      def execute(pre_cmds: nil, do_cmds: nil)
        unless binding_irb?
          puts "`debug` command is only available when IRB is started with binding.irb"
          return
        end

        unless setup_debugger
          puts <<~MSG
            You need to install the debug gem before using this command.
            If you use `bundle exec`, please add `gem "debug"` into your Gemfile.
          MSG
          return
        end

        options = { oneshot: true, hook_call: false }
        if pre_cmds || do_cmds
          options[:command] = ['irb', pre_cmds, do_cmds]
        end
        if DEBUGGER__::LineBreakpoint.instance_method(:initialize).parameters.include?([:key, :skip_src])
          options[:skip_src] = true
        end

        # To make debugger commands like `next` or `continue` work without asking
        # the user to quit IRB after that, we need to exit IRB first and then hit
        # a TracePoint on #debug_break.
        file, lineno = IRB::Irb.instance_method(:debug_break).source_location
        DEBUGGER__::SESSION.add_line_breakpoint(file, lineno + 1, **options)
        # exit current Irb#run call
        throw :IRB_EXIT
      end

      private

      def binding_irb?
        caller.any? do |frame|
          BINDING_IRB_FRAME_REGEXPS.any? do |regexp|
            frame.match?(regexp)
          end
        end
      end

      module SkipPathHelperForIRB
        def skip_internal_path?(path)
          # The latter can be removed once https://github.com/ruby/debug/issues/866 is resolved
          super || path.match?(IRB_DIR) || path.match?('<internal:prelude>')
        end
      end

      def setup_debugger
        unless defined?(DEBUGGER__::SESSION)
          begin
            require "debug/session"
          rescue LoadError # debug.gem is not written in Gemfile
            return false unless load_bundled_debug_gem
          end
          DEBUGGER__.start(nonstop: true)
        end

        unless DEBUGGER__.respond_to?(:capture_frames_without_irb)
          DEBUGGER__.singleton_class.send(:alias_method, :capture_frames_without_irb, :capture_frames)

          def DEBUGGER__.capture_frames(*args)
            frames = capture_frames_without_irb(*args)
            frames.reject! do |frame|
              frame.realpath&.start_with?(IRB_DIR) || frame.path == "<internal:prelude>"
            end
            frames
          end

          DEBUGGER__::ThreadClient.prepend(SkipPathHelperForIRB)
        end

        true
      end

      # This is used when debug.gem is not written in Gemfile. Even if it's not
      # installed by `bundle install`, debug.gem is installed by default because
      # it's a bundled gem. This method tries to activate and load that.
      def load_bundled_debug_gem
        # Discover latest debug.gem under GEM_PATH
        debug_gem = Gem.paths.path.flat_map { |path| Dir.glob("#{path}/gems/debug-*") }.select do |path|
          File.basename(path).match?(/\Adebug-\d+\.\d+\.\d+(\w+)?\z/)
        end.sort_by do |path|
          Gem::Version.new(File.basename(path).delete_prefix('debug-'))
        end.last
        return false unless debug_gem

        # Discover debug/debug.so under extensions for Ruby 3.2+
        ext_name = "/debug/debug.#{RbConfig::CONFIG['DLEXT']}"
        ext_path = Gem.paths.path.flat_map do |path|
          Dir.glob("#{path}/extensions/**/#{File.basename(debug_gem)}#{ext_name}")
        end.first

        # Attempt to forcibly load the bundled gem
        if ext_path
          $LOAD_PATH << ext_path.delete_suffix(ext_name)
        end
        $LOAD_PATH << "#{debug_gem}/lib"
        begin
          require "debug/session"
          puts "Loaded #{File.basename(debug_gem)}"
          true
        rescue LoadError
          false
        end
      end
    end

    class DebugCommand < Debug
      def self.category
        "Debugging"
      end

      def self.description
        command_name = self.name.split("::").last.downcase
        "Start the debugger of debug.gem and run its `#{command_name}` command."
      end
    end
  end
end
