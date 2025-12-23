Brakeman.load_brakeman_dependency 'highline'

module Brakeman
  class InteractiveIgnorer
    def initialize file, warnings
      @ignore_config = Brakeman::IgnoreConfig.new(file, warnings)
      @new_warnings = warnings
      @skip_ignored = false
      @skip_rest = false
      @ignore_rest = false
      @quit = false
      @restart = false
    end

    def start
      file_menu
      initial_menu

      @ignore_config.filter_ignored

      unless @quit
        penultimate_menu
        final_menu
      end

      if @restart
        @restart = false
        start
      end

      @ignore_config
    end

    private

    def file_menu
      loop do
        @ignore_config.file = HighLine.new.ask "Input file: " do |q|
          if @ignore_config.file and not @ignore_config.file.empty?
            q.default = @ignore_config.file
          else
            q.default = "config/brakeman.ignore"
          end
        end

        if File.exist? @ignore_config.file
          @ignore_config.read_from_file
          return
        else
          if yes_or_no "No such file. Continue with empty config? "
            return
          end
        end
      end
    end

    def initial_menu
      HighLine.new.choose do |m|
        m.choice "Inspect all warnings" do
          @skip_ignored = false
          pre_show_help
          process_warnings
        end

        m.choice "Inspect new warnings" do
          @skip_ignored = true
          pre_show_help
          process_warnings
        end

        m.choice "Prune obsolete ignored warnings" do
          prune_obsolete
        end

        m.choice "Skip - use current ignore configuration" do
          @quit = true
          @ignore_config.filter_ignored
        end
      end
    end

    def warning_menu
      HighLine.new.choose do |m|
        m.prompt = "Action: "
        m.layout = :one_line
        m.list_option = ", "
        m.select_by = :name

        m.choice "i"
        m.choice "n"
        m.choice "s"
        m.choice "u"
        m.choice "a"
        m.choice "k"
        m.choice "q"
        m.choice "?" do
          show_help
          "?"
        end
      end
    end

    def pre_show_help
      say "-" * 30
      say "Actions:", :cyan
      show_help
    end

    def show_help
      say <<-HELP
i - Add warning to ignore list
n - Add warning to ignore list and add note
s - Skip this warning (will remain ignored or shown)
u - Remove this warning from ignore list
a - Ignore this warning and all remaining warnings
k - Skip this warning and all remaining warnings
q - Quit, do not update ignored warnings
? - Display this help
      HELP
    end

    def penultimate_menu
      obsolete = @ignore_config.obsolete_fingerprints
      return unless obsolete.any?

      if obsolete.length > 1
        plural = 's'
        verb = 'are'
      else
        plural = ''
        verb = 'is'
      end

      say "\n#{obsolete.length} fingerprint#{plural} #{verb} unused:", :green
      obsolete.each do |obs|
        say obs
      end

      if yes_or_no "\nRemove fingerprint#{plural}?"
        @ignore_config.prune_obsolete
      end
    end

    def prune_obsolete
      @ignore_config.filter_ignored
      obsolete = @ignore_config.obsolete_fingerprints
      @ignore_config.prune_obsolete

      say "Removed #{obsolete.length} obsolete fingerprint#{'s' if obsolete.length > 1} from ignore config.", :yellow
    end

    def final_menu
      summarize_changes

      HighLine.new.choose do |m|
        m.choice "Save changes" do
          save
        end

        m.choice "Start over" do
          start_over
        end

        m.choice "Quit, do not save changes" do
          quit
        end
      end
    end

    def save
      @ignore_config.file = HighLine.new.ask "Output file: " do |q|
        if @ignore_config.file and not @ignore_config.file.empty?
          q.default = @ignore_config.file
        else
          q.default = "config/brakeman.ignore"
        end
      end

      @ignore_config.save_with_old
    end

    def start_over
      reset_config
      @restart = true
    end

    def reset_config
      @ignore_config = Brakeman::IgnoreConfig.new(@ignore_config.file, @new_warnings)
    end

    def process_warnings
      @warning_count = @new_warnings.length

      @new_warnings.each_with_index do |w, index|
        @current_index = index

        if skip_ignored? w or @skip_rest
          next
        elsif @ignore_rest
          ignore w
        elsif @quit or @restart
          return
        else
          ask_about w
        end
      end
    end

    def ask_about warning
      pretty_display warning
      warning_action warning_menu, warning
    end

    def warning_action action, warning
      case action
      when "i"
        ignore warning
      when "n"
        ignore_and_note warning
      when "s"
        # do nothing
      when "u"
        unignore warning
      when "a"
        ignore_rest warning
      when "k"
        skip_rest warning
      when "q"
        quit
      when "?"
        ask_about warning
      else
        raise "Unexpected action"
      end
    end

    def ignore warning
      @ignore_config.ignore warning
    end

    def ignore_and_note warning
      note = HighLine.new.ask("Note: ")
      @ignore_config.ignore warning
      @ignore_config.add_note warning, note
    end

    def unignore warning
      @ignore_config.unignore warning
    end

    def skip_rest warning
      @skip_rest = true
    end

    def ignore_rest warning
      ignore warning
      @ignore_rest = true
    end

    def quit
      reset_config
      @ignore_config.read_from_file
      @ignore_config.filter_ignored
      @quit = true
    end

    def pretty_display warning
      progress = "#{@current_index + 1}/#{@warning_count}"
      say "-------- #{progress} #{"-" * (20 - progress.length)}", :cyan
      show_confidence warning

      label "Category"
      say warning.warning_type

      label "Message"
      say warning.message

      if warning.code
        label "Code"
        say warning.format_code
      end

      if warning.file
        label "File"
        say warning.file.relative
      end

      if warning.line
        label "Line"
        say warning.line
      end

      if already_ignored? warning
        show_note warning
        say "Already ignored", :red
      end

      say ""
    end

    def already_ignored? warning
      @ignore_config.ignored? warning
    end

    def skip_ignored? warning
      @skip_ignored and already_ignored? warning
    end

    def summarize_changes
      say "-" * 30

      say "Ignoring #{@ignore_config.ignored_warnings.length} warnings", :yellow
      say "Showing #{@ignore_config.shown_warnings.length} warnings", :green
    end

    def label name
      say "#{name}: ", :green
    end

    def show_confidence warning
      label "Confidence"

      case warning.confidence
      when 0
        say "High", :red
      when 1
        say "Medium", :yellow
      when 2
        say "Weak", :cyan
      else
        say "Unknown"
      end
    end

    def show_note warning
      note = @ignore_config.note_for warning

      if note
        label "Note"
        say note
      end
    end

    def say text, color = nil
      text = text.to_s

      if color
        HighLine.new.say HighLine.new.color(text, color)
      else
        HighLine.new.say text
      end
    end

    def yes_or_no message
      answer = HighLine.new.ask message do |q|
        q.in = ["y", "n", "yes", "no"]
      end

      answer.match /^y/i
    end
  end
end
