# coding: utf-8

#--
# highline.rb
#
#  Created by James Edward Gray II on 2005-04-26.
#  Copyright 2005 Gray Productions. All rights reserved.
#
# See HighLine for documentation.
#
# This is Free Software.  See LICENSE and COPYING for details.

require "English"
require "erb"
require "optparse"
require "stringio"
require "abbrev"
require "highline/terminal"
require "highline/custom_errors"
require "highline/question"
require "highline/question_asker"
require "highline/menu"
require "highline/color_scheme"
require "highline/style"
require "highline/version"
require "highline/statement"
require "highline/list_renderer"
require "highline/builtin_styles"

#
# A HighLine object is a "high-level line oriented" shell over an input and an
# output stream.  HighLine simplifies common console interaction, effectively
# replacing {Kernel#puts} and {Kernel#gets}.  User code can simply specify the
# question to ask and any details about user interaction, then leave the rest
# of the work to HighLine.  When {HighLine#ask} returns, you'll have the answer
# you requested, even if HighLine had to ask many times, validate results,
# perform range checking, convert types, etc.
#
# @example Basic usage
#   cli = HighLine.new
#   answer = cli.ask "What do you think?"
#   puts "You have answered: #{answer}"
#
class HighLine
  include BuiltinStyles
  include CustomErrors

  extend SingleForwardable
  def_single_delegators :@default_instance, :agree, :ask, :choose, :say,
                        :use_color=, :use_color?, :reset_use_color,
                        :track_eof=, :track_eof?,
                        :color, :uncolor, :color_code

  class << self
    attr_accessor :default_instance

    # Pass ColorScheme to set a HighLine color scheme.
    attr_accessor :color_scheme

    # Returns +true+ if HighLine is currently using a color scheme.
    def using_color_scheme?
      true if @color_scheme
    end

    # Reset color scheme to default (+nil+)
    def reset_color_scheme
      self.color_scheme = nil
    end

    # Reset HighLine to default.
    # Clears Style index and resets color_scheme and use_color settings.
    def reset
      Style.clear_index
      reset_color_scheme
      reset_use_color
    end

    # For checking if the current version of HighLine supports RGB colors
    # Usage: HighLine.supports_rgb_color? rescue false
    #  using rescue for compatibility with older versions
    # Note: color usage also depends on HighLine.use_color being set
    # TODO: Discuss removing this method
    def supports_rgb_color?
      true
    end
  end

  # The setting used to control color schemes.
  @color_scheme = nil

  #
  # Create an instance of HighLine connected to the given _input_
  # and _output_ streams.
  #
  # @param input [IO] the default input stream for HighLine.
  # @param output [IO] the default output stream for HighLine.
  # @param wrap_at [Integer] all statements outputed through
  #   HighLine will be wrapped to this column size if set.
  # @param page_at [Integer] page size and paginating.
  # @param indent_size [Integer] indentation size in spaces.
  # @param indent_level [Integer] how deep is indentated.
  def initialize(input = $stdin, output = $stdout,
                 wrap_at = nil, page_at = nil,
                 indent_size = 3, indent_level = 0)
    @input   = input
    @output  = output

    @multi_indent = true
    @indent_size  = indent_size
    @indent_level = indent_level

    self.wrap_at = wrap_at
    self.page_at = page_at

    @header   = nil
    @prompt   = nil
    @key      = nil

    @use_color = default_use_color
    @track_eof = true # The setting used to disable EOF tracking.
    @terminal = HighLine::Terminal.get_terminal(input, output)
  end

  # Set it to false to disable ANSI coloring
  attr_accessor :use_color

  # Returns truethy if HighLine instance is currently using color escapes.
  def use_color?
    use_color
  end

  # Resets the use of color.
  def reset_use_color
    @use_color = true
  end

  # Pass +false+ to turn off HighLine's EOF tracking.
  attr_accessor :track_eof

  # Returns true if HighLine is currently tracking EOF for input.
  def track_eof?
    true if track_eof
  end

  # @return [Integer] The current column setting for wrapping output.
  attr_reader :wrap_at

  # @return [Integer] The current row setting for paging output.
  attr_reader :page_at

  # @return [Boolean] Indentation over multiple lines
  attr_accessor :multi_indent

  # @return [Integer] The indentation size in characters
  attr_accessor :indent_size

  # @return [Integer] The indentation level
  attr_accessor :indent_level

  # @return [IO] the default input stream for a HighLine instance
  attr_reader :input

  # @return [IO] the default output stream for a HighLine instance
  attr_reader :output

  # When gathering a Hash with {QuestionAsker#gather_hash},
  # it tracks the current key being asked.
  #
  # @todo We should probably move this into the HighLine::Question
  #   object.
  attr_accessor :key

  # System specific that responds to #initialize_system_extensions,
  # #terminal_size, #raw_no_echo_mode, #restore_mode, #get_character.
  # It polymorphically handles specific cases for different platforms.
  # @return [HighLine::Terminal]
  attr_reader :terminal

  #
  # A shortcut to HighLine.ask() a question that only accepts "yes" or "no"
  # answers ("y" and "n" are allowed) and returns +true+ or +false+
  # (+true+ for "yes").  If provided a +true+ value, _character_ will cause
  # HighLine to fetch a single character response. A block can be provided
  # to further configure the question as in HighLine.ask()
  #
  # Raises EOFError if input is exhausted.
  #
  # @param yes_or_no_question [String] a question that accepts yes and no as
  #   answers
  # @param character [Boolean, :getc] character mode to be passed to
  #   Question#character
  # @see Question#character
  def agree(yes_or_no_question, character = nil)
    ask(yes_or_no_question, ->(yn) { yn.downcase[0] == "y" }) do |q|
      q.validate                 = /\A(?:y(?:es)?|no?)\Z/i
      q.responses[:not_valid]    = 'Please enter "yes" or "no".'
      q.responses[:ask_on_error] = :question
      q.character                = character
      q.completion               = %w[yes no]

      yield q if block_given?
    end
  end

  #
  # This method is the primary interface for user input.  Just provide a
  # _question_ to ask the user, the _answer_type_ you want returned, and
  # optionally a code block setting up details of how you want the question
  # handled.  See {#say} for details on the format of _question_, and
  # {Question} for more information about _answer_type_ and what's
  # valid in the code block.
  #
  # Raises EOFError if input is exhausted.
  #
  # @param (see Question.build)
  # @return answer converted to the class in answer_type
  def ask(template_or_question, answer_type = nil, &details)
    question = Question.build(template_or_question, answer_type, &details)

    if question.gather
      QuestionAsker.new(question, self).gather_answers
    else
      QuestionAsker.new(question, self).ask_once
    end
  end

  #
  # This method is HighLine's menu handler.  For simple usage, you can just
  # pass all the menu items you wish to display.  At that point, choose() will
  # build and display a menu, walk the user through selection, and return
  # their choice among the provided items.  You might use this in a case
  # statement for quick and dirty menus.
  #
  # However, choose() is capable of much more.  If provided, a block will be
  # passed a HighLine::Menu object to configure.  Using this method, you can
  # customize all the details of menu handling from index display, to building
  # a complete shell-like menuing system.  See HighLine::Menu for all the
  # methods it responds to.
  #
  # Raises EOFError if input is exhausted.
  #
  # @param items [Array<String>]
  # @param details [Proc] to be passed to Menu.new
  # @return [String] answer
  def choose(*items, &details)
    menu = Menu.new(&details)
    menu.choices(*items) unless items.empty?

    # Set auto-completion
    menu.completion = menu.options

    # Set _answer_type_ so we can double as the Question for ask().
    # menu.option = normal menu selection, by index or name
    menu.answer_type = menu.shell ? shell_style_lambda(menu) : menu.options

    selected = ask(menu)
    return unless selected

    if menu.shell
      if menu.gather
        selection = []
        details = []
        selected.each do |value|
          selection << value[0]
          details << value[1]
        end
      else
        selection, details = selected
      end
    else
      selection = selected
    end

    if menu.gather
      menu.gather_selected(self, selection, details)
    else
      menu.select(self, selection, details)
    end
  end

  # Convenience method to craft a lambda suitable for
  # beind used in autocompletion operations by {#choose}
  # @return [lambda] lambda to be used in autocompletion operations

  def shell_style_lambda(menu)
    lambda do |command| # shell-style selection
      first_word = command.to_s.split.first || ""

      options = menu.options
      options.extend(OptionParser::Completion)
      answer = options.complete(first_word)

      raise Question::NoAutoCompleteMatch unless answer

      [answer.last, command.sub(/^\s*#{first_word}\s*/, "")]
    end
  end

  #
  # This method provides easy access to ANSI color sequences, without the user
  # needing to remember to CLEAR at the end of each sequence.  Just pass the
  # _string_ to color, followed by a list of _colors_ you would like it to be
  # affected by.  The _colors_ can be HighLine class constants, or symbols
  # (:blue for BLUE, for example).  A CLEAR will automatically be embedded to
  # the end of the returned String.
  #
  # This method returns the original _string_ unchanged if use_color?
  # is +false+.
  #
  # @param string [String] string to be colored
  # @param colors [Array<Symbol>] array of colors like [:red, :blue]
  # @return [String] (ANSI escaped) colored string
  # @example
  #    cli = HighLine.new
  #    cli.color("Sustainable", :green, :bold)
  #    # => "\e[32m\e[1mSustainable\e[0m"
  #
  #    # As class method (delegating to HighLine.default_instance)
  #    HighLine.color("Sustainable", :green, :bold)
  #
  def color(string, *colors)
    return string unless use_color?
    HighLine.Style(*colors).color(string)
  end

  # In case you just want the color code, without the embedding and
  # the CLEAR sequence.
  #
  # @param colors [Array<Symbol>]
  # @return [String] ANSI escape code for the given colors.
  #
  # @example
  #   s = HighLine.Style(:red, :blue)
  #   s.code # => "\e[31m\e[34m"
  #
  #   HighLine.color_code(:red, :blue) # => "\e[31m\e[34m"
  #
  #   cli = HighLine.new
  #   cli.color_code(:red, :blue) # => "\e[31m\e[34m"
  #
  def color_code(*colors)
    HighLine.Style(*colors).code
  end

  # Remove color codes from a string.
  # @param string [String] to be decolorized
  # @return [String] without the ANSI escape sequence (colors)
  def uncolor(string)
    Style.uncolor(string)
  end

  # Renders a list of itens using a {ListRenderer}
  # @param items [Array]
  # @param mode [Symbol]
  # @param option
  # @return [String]
  # @see ListRenderer#initialize ListRenderer#initialize for parameter details
  def list(items, mode = :rows, option = nil)
    ListRenderer.new(items, mode, option, self).render
  end

  #
  # The basic output method for HighLine objects.  If the provided _statement_
  # ends with a space or tab character, a newline will not be appended (output
  # will be flush()ed).  All other cases are passed straight to Kernel.puts().
  #
  # The _statement_ argument is processed as an ERb template, supporting
  # embedded Ruby code.  The template is evaluated within a HighLine
  # instance's binding for providing easy access to the ANSI color constants
  # and the HighLine#color() method.
  #
  # @param statement [Statement, String] what to be said
  def say(statement)
    statement = render_statement(statement)
    return if statement.empty?

    statement = (indentation + statement)

    # Don't add a newline if statement ends with whitespace, OR
    # if statement ends with whitespace before a color escape code.
    if /[ \t](\e\[\d+(;\d+)*m)?\Z/ =~ statement
      output.print(statement)
      output.flush
    else
      output.puts(statement)
    end
  end

  # Renders a statement using {HighLine::Statement}
  # @param statement [String] any string
  # @return [Statement] rendered statement
  def render_statement(statement)
    Statement.new(statement, self).to_s
  end

  #
  # Set to an integer value to cause HighLine to wrap output lines at the
  # indicated character limit.  When +nil+, the default, no wrapping occurs.  If
  # set to <tt>:auto</tt>, HighLine will attempt to determine the columns
  # available for the <tt>@output</tt> or use a sensible default.
  #
  def wrap_at=(setting)
    @wrap_at = setting == :auto ? output_cols : setting
  end

  #
  # Set to an integer value to cause HighLine to page output lines over the
  # indicated line limit.  When +nil+, the default, no paging occurs.  If
  # set to <tt>:auto</tt>, HighLine will attempt to determine the rows available
  # for the <tt>@output</tt> or use a sensible default.
  #
  def page_at=(setting)
    @page_at = setting == :auto ? output_rows - 2 : setting
  end

  #
  # Outputs indentation with current settings
  #
  def indentation
    " " * @indent_size * @indent_level
  end

  #
  # Executes block or outputs statement with indentation
  #
  # @param increase [Integer] how much to increase indentation
  # @param statement [Statement, String] to be said
  # @param multiline [Boolean]
  # @return [void]
  # @see #multi_indent
  def indent(increase = 1, statement = nil, multiline = nil)
    @indent_level += increase
    multi = @multi_indent
    @multi_indent ||= multiline
    begin
      if block_given?
        yield self
      else
        say(statement)
      end
    ensure
      @multi_indent = multi
      @indent_level -= increase
    end
  end

  #
  # Outputs newline
  #
  def newline
    @output.puts
  end

  #
  # Returns the number of columns for the console, or a default it they cannot
  # be determined.
  #
  def output_cols
    return 80 unless @output.tty?
    terminal.terminal_size.first
  rescue NoMethodError
    return 80
  end

  #
  # Returns the number of rows for the console, or a default if they cannot be
  # determined.
  #
  def output_rows
    return 24 unless @output.tty?
    terminal.terminal_size.last
  rescue NoMethodError
    return 24
  end

  # Call #puts on the HighLine's output stream
  # @param args [String] same args for Kernel#puts
  def puts(*args)
    @output.puts(*args)
  end

  #
  # Creates a new HighLine instance with the same options
  #
  def new_scope
    self.class.new(@input, @output, @wrap_at,
                   @page_at, @indent_size, @indent_level)
  end

  private

  # Adds a layer of scope (new_scope) to ask a question inside a
  # question, without destroying instance data
  def confirm(question)
    new_scope.agree(question.confirm_question(self))
  end

  #
  # A helper method used by HighLine::Question.verify_match
  # for finding whether a list of answers match or differ
  # from each other.
  #
  def unique_answers(list)
    (list.respond_to?(:values) ? list.values : list).uniq
  end

  def last_answer(answers)
    answers.respond_to?(:values) ? answers.values.last : answers.last
  end

  # Get response one line at time
  # @param question [Question]
  # @return [String] response
  def get_response_line_mode(question)
    if question.echo == true && !question.limit
      get_line(question)
    else
      get_line_raw_no_echo_mode(question)
    end
  end

  #
  # Read a line of input from the input stream and process whitespace as
  # requested by the Question object.
  #
  # If Question's _readline_ property is set, that library will be used to
  # fetch input.  *WARNING*:  This ignores the currently set input stream.
  #
  # Raises EOFError if input is exhausted.
  #
  def get_line(question)
    terminal.get_line(question, self)
  end

  def get_line_raw_no_echo_mode(question)
    line = ""

    terminal.raw_no_echo_mode_exec do
      loop do
        character = terminal.get_character
        break unless character
        break if ["\n", "\r"].include? character

        # honor backspace and delete
        if character == "\b" || character == "\u007F"
          chopped = line.chop!
          output_erase_char if chopped && question.echo
        elsif character == "\e"
          ignore_arrow_key
        else
          line << character
          say_last_char_or_echo_char(line, question)
        end

        @output.flush

        break if line_overflow_for_question?(line, question)
      end
    end

    say_new_line_or_overwrite(question)

    question.format_answer(line)
  end

  def say_new_line_or_overwrite(question)
    if question.overwrite
      @output.print("\r#{HighLine.Style(:erase_line).code}")
      @output.flush
    else
      say("\n")
    end
  end

  def ignore_arrow_key
    2.times do
      terminal.get_character
    end
  end

  def say_last_char_or_echo_char(line, question)
    @output.print(line[-1]) if question.echo == true
    @output.print(question.echo) if question.echo && question.echo != true
  end

  def line_overflow_for_question?(line, question)
    question.limit && line.size == question.limit
  end

  def output_erase_char
    @output.print("\b#{HighLine.Style(:erase_char).code}")
  end

  # Get response using #getc
  # @param question [Question]
  # @return [String] response
  def get_response_getc_mode(question)
    terminal.raw_no_echo_mode_exec do
      response = @input.getc
      question.format_answer(response)
    end
  end

  # Get response each character per turn
  # @param question [Question]
  # @return [String] response
  def get_response_character_mode(question)
    terminal.raw_no_echo_mode_exec do
      response = terminal.get_character
      if question.overwrite
        erase_current_line
      else
        echo = question.get_echo_for_response(response)
        say("#{echo}\n")
      end
      question.format_answer(response)
    end
  end

  def erase_current_line
    @output.print("\r#{HighLine.Style(:erase_line).code}")
    @output.flush
  end

  public :get_response_character_mode, :get_response_line_mode
  public :get_response_getc_mode

  def actual_length(text)
    Wrapper.actual_length text
  end

  # Check to see if there's already a HighLine.default_instance or if
  # this is the first time the method is called (eg: at
  # HighLine.default_instance initialization).
  # If there's already one, copy use_color settings.
  # This is here most to help migrate code from HighLine 1.7.x to 2.0.x
  #
  # @return [Boolean]
  def default_use_color
    if HighLine.default_instance
      HighLine.default_instance.use_color
    else
      true
    end
  end
end

HighLine.default_instance = HighLine.new

require "highline/string"
