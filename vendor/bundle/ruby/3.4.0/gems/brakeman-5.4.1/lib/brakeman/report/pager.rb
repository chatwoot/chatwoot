module Brakeman
  class Pager
    def initialize tracker, pager = :less, output = $stdout
      @tracker = tracker
      @pager = pager
      @output = output
      @less_available = @less_options = nil
    end

    def page_report report, format
      if @pager == :less
        set_color
      end

      text = report.format(format)

      if in_ci?
        no_pager text
      else
        page_output text
      end
    end

    def page_output text
      case @pager
      when :none
        no_pager text
      when :highline
        page_via_highline text
      when :less
        if less_available?
          page_via_less text
        else
          page_via_highline text
        end
      else
        no_pager text
      end
    end

    def no_pager text
      @output.puts text
    end

    def page_via_highline text
      Brakeman.load_brakeman_dependency 'highline'
      h = ::HighLine.new($stdin, @output)
      h.page_at = :auto
      h.say text
    end

    def page_via_less text
      # Adapted from https://github.com/piotrmurach/tty-pager/

      write_io = open("|less #{less_options.join}", 'w')
      pid = write_io.pid

      write_io.write(text)
      write_io.close

      Process.waitpid2(pid, Process::WNOHANG)
    rescue Errno::ECHILD
      # on jruby 9x waiting on pid raises (per tty-pager)
      true
    rescue => e
      warn "[Error] #{e}"
      warn "[Error] Could not use pager. Set --no-pager to avoid this issue."
      no_pager text
    end

    def in_ci?
      ci = ENV["CI"]

      ci.is_a? String and ci.downcase == "true"
    end

    def less_available?
      return @less_available unless @less_available.nil?

      @less_available = system("which less > /dev/null")
    end

    def less_options
      # -R show colors
      # -F exit if output fits on one screen
      # -X do not clear screen after less exits

      return @less_options if @less_options

      @less_options = []

      if system("which less > /dev/null")
        less_help = `less -?`

        ["-R ", "-F ", "-X "].each do |opt|
          if less_help.include? opt
            @less_options << opt
          end
        end
      end

      @less_options
    end

    def set_color
      return unless @tracker

      unless less_options.include? "-R " or @tracker.options[:output_color] == :force
        @tracker.options[:output_color] = false
      end
    end
  end
end
