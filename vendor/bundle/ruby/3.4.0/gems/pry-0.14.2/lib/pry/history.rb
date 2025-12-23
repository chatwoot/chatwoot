# frozen_string_literal: true

class Pry
  # The History class is responsible for maintaining the user's input history,
  # both internally and within Readline.
  class History
    def self.default_file
      history_file =
        if (xdg_home = Pry::Env['XDG_DATA_HOME'])
          # See XDG Base Directory Specification at
          # https://standards.freedesktop.org/basedir-spec/basedir-spec-0.8.html
          xdg_home + '/pry/pry_history'
        elsif File.exist?(File.expand_path('~/.pry_history'))
          '~/.pry_history'
        else
          '~/.local/share/pry/pry_history'
        end
      File.expand_path(history_file)
    end

    attr_accessor :loader, :saver

    # @return [Fixnum] Number of lines in history when Pry first loaded.
    attr_reader :original_lines

    # @return [Integer] total number of lines, including original lines
    attr_reader :history_line_count

    def initialize(options = {})
      @history = options[:history] || []
      @history_line_count = @history.count
      @file_path = options[:file_path]
      @original_lines = 0
      @loader = method(:read_from_file)
      @saver = method(:save_to_file)
    end

    # Load the input history using `History.loader`.
    # @return [Integer] The number of lines loaded
    def load
      @loader.call do |line|
        next if invalid_readline_line?(line)

        @history << line.chomp
        @original_lines += 1
        @history_line_count += 1
      end
    end

    # Add a line to the input history, ignoring blank and duplicate lines.
    # @param [String] line
    # @return [String] The same line that was passed in
    def push(line)
      return line if line.empty? || invalid_readline_line?(line)

      begin
        last_line = @history[-1]
      rescue IndexError
        last_line = nil
      end

      return line if line == last_line

      @history << line
      @history_line_count += 1
      @saver.call(line) if !should_ignore?(line) && Pry.config.history_save

      line
    end
    alias << push

    # Clear this session's history. This won't affect the contents of the
    # history file.
    def clear
      @history.clear
      @history_line_count = 0
      @original_lines = 0
    end

    # @return [Fixnum] The number of lines in history from just this session.
    def session_line_count
      @history_line_count - @original_lines
    end

    # Return an Array containing all stored history.
    # @return [Array<String>] An Array containing all lines of history loaded
    #   or entered by the user in the current session.
    def to_a
      @history.to_a
    end

    # Filter the history with the histignore options
    # @return [Array<String>] An array containing all the lines that are not
    #   included in the histignore.
    def filter(history)
      history.select { |l| l unless should_ignore?(l) }
    end

    private

    # Check if the line match any option in the histignore
    # [Pry.config.history_ignorelist]
    # @return [Boolean] a boolean that notifies if the line was found in the
    #   histignore array.
    def should_ignore?(line)
      hist_ignore = Pry.config.history_ignorelist
      return false if hist_ignore.nil? || hist_ignore.empty?

      hist_ignore.any? { |p| line.to_s.match(p) }
    end

    # The default loader. Yields lines from `Pry.config.history_file`.
    def read_from_file
      path = history_file_path

      File.foreach(path) { |line| yield(line) } if File.exist?(path)
    rescue SystemCallError => error
      warn "Unable to read history file: #{error.message}"
    end

    # The default saver. Appends the given line to `Pry.config.history_file`.
    def save_to_file(line)
      history_file.puts line if history_file
    end

    # The history file, opened for appending.
    def history_file
      if defined?(@history_file)
        @history_file
      else
        unless File.exist?(history_file_path)
          FileUtils.mkdir_p(File.dirname(history_file_path))
        end
        @history_file = File.open(history_file_path, 'a', 0o600).tap do |file|
          file.sync = true
        end
      end
    rescue SystemCallError => error
      warn "Unable to write history file: #{error.message}"
      @history_file = false
    end

    def history_file_path
      File.expand_path(@file_path || Pry.config.history_file)
    end

    def invalid_readline_line?(line)
      # `Readline::HISTORY << line` raises an `ArgumentError` if `line`
      # includes a null byte
      line.include?("\0")
    end
  end
end
