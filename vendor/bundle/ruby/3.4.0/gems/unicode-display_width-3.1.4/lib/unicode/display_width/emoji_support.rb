# require "rbconfig"
# RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ # windows

module Unicode
  class DisplayWidth
    module EmojiSupport
      # Tries to find out which terminal emulator is used to
      # set emoji: config to best suiting value
      #
      # Please also see section in README.md and
      # misc/terminal-emoji-width.rb
      #
      # Please note: Many terminals do not set any ENV vars,
      # maybe CSI queries can help?
      def self.recommended
        if ENV["CI"]
          return :rqi
        end

        case ENV["TERM_PROGRAM"]
        when "iTerm.app"
          return :all
        when "Apple_Terminal"
          return :rgi_at
        when "WezTerm"
          return :all_no_vs16
        end

        case ENV["TERM"]
        when "contour","foot"
          # konsole: all, how to detect?
          return :all
        when /kitty/
          return :vs16
        end

        if ENV["WT_SESSION"] # Windows Terminal
          return :vs16
        end

        # As of last time checked: gnome-terminal, vscode, alacritty
        :none
      end

      # Maybe: Implement something like https://github.com/jquast/ucs-detect
      #        which uses the terminal cursor to check for best support level
      #        at runtime
      # def self.detect!
      # end
    end
  end
end
