# coding: utf-8

#--
# menu.rb
#
#  Created by Gregory Thomas Brown on 2005-05-10.
#  Copyright 2005. All rights reserved.
#
#  This is Free Software.  See LICENSE and COPYING for details.

require "highline/question"
require "highline/menu/item"

class HighLine
  #
  # Menu objects encapsulate all the details of a call to
  # {HighLine#choose HighLine#choose}.
  # Using the accessors and {Menu#choice} and {Menu#choices}, the block passed
  # to {HighLine#choose} can detail all aspects of menu display and control.
  #
  class Menu < Question
    # Pass +false+ to _color_ to turn off HighLine::Menu's
    # index coloring.
    # Pass a color and the Menu's indices will be colored.
    class << self
      attr_writer :index_color
    end

    # Initialize it
    self.index_color = false

    # Returns color used for coloring Menu's indices
    class << self
      attr_reader :index_color
    end

    #
    # Create an instance of HighLine::Menu.  All customization is done
    # through the passed block, which should call accessors, {#choice} and
    # {#choices} as needed to define the Menu.  Note that Menus are also
    # {HighLine::Question Questions}, so all that functionality is available
    # to the block as well.
    #
    # @example Implicit menu creation through HighLine#choose
    #   cli = HighLine.new
    #   answer = cli.choose do |menu|
    #     menu.prompt = "Please choose your favorite programming language?  "
    #     menu.choice(:ruby) { say("Good choice!") }
    #     menu.choices(:python, :perl) { say("Not from around here, are you?") }
    #   end

    def initialize
      #
      # Initialize Question objects with ignored values, we'll
      # adjust ours as needed.
      #
      super("Ignored", [], &nil) # avoiding passing the block along

      @items           = []
      @hidden_items    = []
      @help            = Hash.new("There's no help for that topic.")

      @index           = :number
      @index_suffix    = ". "
      @select_by       = :index_or_name
      @flow            = :rows
      @list_option     = nil
      @header          = nil
      @prompt          = "?  "
      @layout          = :list
      @shell           = false
      @nil_on_handled  = false

      # Used for coloring Menu indices.
      # Set it to default. But you may override it.
      @index_color     = self.class.index_color

      # Override Questions responses, we'll set our own.
      @responses       = {}
      # Context for action code.
      @highline        = nil

      yield self if block_given?

      init_help if @shell && !@help.empty?
    end

    #
    # An _index_ to append to each menu item in display.  See
    # Menu.index=() for details.
    #
    attr_reader   :index
    #
    # The String placed between an _index_ and a menu item.  Defaults to
    # ". ".  Switches to " ", when _index_ is set to a String (like "-").
    #
    attr_accessor :index_suffix
    #
    # The _select_by_ attribute controls how the user is allowed to pick a
    # menu item.  The available choices are:
    #
    # <tt>:index</tt>::          The user is allowed to type the numerical
    #                            or alphabetical index for their selection.
    # <tt>:index_or_name</tt>::  Allows both methods from the
    #                            <tt>:index</tt> option and the
    #                            <tt>:name</tt> option.
    # <tt>:name</tt>::           Menu items are selected by typing a portion
    #                            of the item name that will be
    #                            auto-completed.
    #
    attr_accessor :select_by
    #
    # This attribute is passed directly on as the mode to HighLine.list() by
    # all the preset layouts.  See that method for appropriate settings.
    #
    attr_accessor :flow
    #
    # This setting is passed on as the third parameter to HighLine.list()
    # by all the preset layouts.  See that method for details of its
    # effects.  Defaults to +nil+.
    #
    attr_accessor :list_option
    #
    # Used by all the preset layouts to display title and/or introductory
    # information, when set.  Defaults to +nil+.
    #
    attr_accessor :header
    #
    # Used by all the preset layouts to ask the actual question to fetch a
    # menu selection from the user.  Defaults to "?  ".
    #
    attr_accessor :prompt
    #
    # An ERb _layout_ to use when displaying this Menu object.  See
    # Menu.layout=() for details.
    #
    attr_reader   :layout
    #
    # When set to +true+, responses are allowed to be an entire line of
    # input, including details beyond the command itself.  Only the first
    # "word" of input will be matched against the menu choices, but both the
    # command selected and the rest of the line will be passed to provided
    # action blocks.  Defaults to +false+.
    #
    attr_accessor :shell
    #
    # When +true+, any selected item handled by provided action code will
    # return +nil+, instead of the results to the action code.  This may
    # prove handy when dealing with mixed menus where only the names of
    # items without any code (and +nil+, of course) will be returned.
    # Defaults to +false+.
    #
    attr_accessor :nil_on_handled
    #
    # The color of the index when displaying the menu. See Style class for
    # available colors.
    #
    attr_accessor :index_color

    #
    # Adds _name_ to the list of available menu items.  Menu items will be
    # displayed in the order they are added.
    #
    # An optional _action_ can be associated with this name and if provided,
    # it will be called if the item is selected.  The result of the method
    # will be returned, unless _nil_on_handled_ is set (when you would get
    # +nil+ instead).  In _shell_ mode, a provided block will be passed the
    # command chosen and any details that followed the command.  Otherwise,
    # just the command is passed.  The <tt>@highline</tt> variable is set to
    # the current HighLine context before the action code is called and can
    # thus be used for adding output and the like.
    #
    # @param name [#to_s] menu item title/header/name to be displayed.
    # @param action [Proc] callback action to be run when the item is selected.
    # @param help [String] help/hint string to be displayed.
    # @return [void]
    # @example (see HighLine::Menu#initialize)
    # @example Use of help string on menu items
    #   cli = HighLine.new
    #   cli.choose do |menu|
    #     menu.shell = true
    #
    #     menu.choice(:load, text: 'Load a file',
    #                 help: "Load a file using your favourite editor.")
    #     menu.choice(:save, help: "Save data in file.")
    #     menu.choice(:quit, help: "Exit program.")
    #
    #     menu.help("rules", "The rules of this system are as follows...")
    #   end

    def choice(name, help = nil, text = nil, &action)
      item = Menu::Item.new(name, text: text, help: help, action: action)
      @items << item
      @help.merge!(item.item_help)
      update_responses # rebuild responses based on our settings
    end

    #
    # This method helps reduce the namespaces in the original call,
    # which would look like this: HighLine::Menu::Item.new(...)
    # With #build_item, it looks like this: menu.build_item(...)
    # @param *args splat args, the same args you would pass to an
    #   initialization of HighLine::Menu::Item
    # @return [HighLine::Menu::Item] the menu item

    def build_item(*args)
      Menu::Item.new(*args)
    end

    #
    # Adds an item directly to the menu. If you want more configuration
    # or options, use this method
    #
    # @param item [Menu::Item] item containing choice fields and more
    # @return [void]

    def add_item(item)
      @items << item
      @help.merge!(item.item_help)
      update_responses
    end

    #
    # A shortcut for multiple calls to the sister method {#choice}.  <b>Be
    # warned:</b>  An _action_ set here will apply to *all* provided
    # _names_.  This is considered to be a feature, so you can easily
    # hand-off interface processing to a different chunk of code.
    # @param names [Array<#to_s>] menu item titles/headers/names to be
    #   displayed.
    # @param action (see #choice)
    # @return [void]
    # @example (see HighLine::Menu#initialize)
    #
    # choice has more options available to you, like longer text or help (and
    # of course, individual actions)
    #
    def choices(*names, &action)
      names.each { |n| choice(n, &action) }
    end

    # Identical to {#choice}, but the item will not be listed for the user.
    # @see #choice
    # @param name (see #choice)
    # @param help (see #choice)
    # @param action (see #choice)
    # @return (see #choice)

    def hidden(name, help = nil, &action)
      item = Menu::Item.new(name, text: name, help: help, action: action)
      @hidden_items << item
      @help.merge!(item.item_help)
    end

    #
    # Sets the indexing style for this Menu object.  Indexes are appended to
    # menu items, when displayed in list form.  The available settings are:
    #
    # <tt>:number</tt>::   Menu items will be indexed numerically, starting
    #                      with 1.  This is the default method of indexing.
    # <tt>:letter</tt>::   Items will be indexed alphabetically, starting
    #                      with a.
    # <tt>:none</tt>::     No index will be appended to menu items.
    # <i>any String</i>::  Will be used as the literal _index_.
    #
    # Setting the _index_ to <tt>:none</tt> or a literal String also adjusts
    # _index_suffix_ to a single space and _select_by_ to <tt>:name</tt>.
    # Because of this, you should make a habit of setting the _index_ first.
    #
    def index=(style)
      @index = style

      return unless @index == :none || @index.is_a?(::String)

      # Default settings.
      @index_suffix = " "
      @select_by    = :name
    end

    #
    # Initializes the help system by adding a <tt>:help</tt> choice, some
    # action code, and the default help listing.
    #
    def init_help
      return if @items.include?(:help)

      topics    = @help.keys.sort
      help_help =
        if @help.include?("help")
          @help["help"]
        else
          "This command will display helpful messages about " \
            "functionality, like this one.  To see the help for " \
            "a specific topic enter:\n\thelp [TOPIC]\nTry asking " \
            "for help on any of the following:\n\n" \
            "<%= list(#{topics.inspect}, :columns_across) %>"
        end

      choice(:help, help_help) do |_command, topic|
        topic.strip!
        topic.downcase!
        if topic.empty?
          @highline.say(@help["help"])
        else
          @highline.say("= #{topic}\n\n#{@help[topic]}")
        end
      end
    end

    #
    # Used to set help for arbitrary topics.  Use the topic <tt>"help"</tt>
    # to override the default message. Mainly for internal use.
    #
    # @param topic [String] the menu item header/title/name to be associated
    #   with a help message.
    # @param help [String] the help message to be associated with the menu
    #   item/title/name.
    def help(topic, help)
      @help[topic] = help
    end

    #
    # Setting a _layout_ with this method also adjusts some other attributes
    # of the Menu object, to ideal defaults for the chosen _layout_.  To
    # account for that, you probably want to set a _layout_ first in your
    # configuration block, if needed.
    #
    # Accepted settings for _layout_ are:
    #
    # <tt>:list</tt>::         The default _layout_.  The _header_ if set
    #                          will appear at the top on its own line with
    #                          a trailing colon.  Then the list of menu
    #                          items will follow.  Finally, the _prompt_
    #                          will be used as the ask()-like question.
    # <tt>:one_line</tt>::     A shorter _layout_ that fits on one line.
    #                          The _header_ comes first followed by a
    #                          colon and spaces, then the _prompt_ with menu
    #                          items between trailing parenthesis.
    # <tt>:menu_only</tt>::    Just the menu items, followed up by a likely
    #                          short _prompt_.
    # <i>any ERb String</i>::  Will be taken as the literal _layout_.  This
    #                          String can access <tt>header</tt>,
    #                          <tt>menu</tt> and <tt>prompt</tt>, but is
    #                          otherwise evaluated in the TemplateRenderer
    #                          context so each method is properly delegated.
    #
    # If set to either <tt>:one_line</tt>, or <tt>:menu_only</tt>, _index_
    # will default to <tt>:none</tt> and _flow_ will default to
    # <tt>:inline</tt>.
    #
    def layout=(new_layout)
      @layout = new_layout

      # Default settings.
      case @layout
      when :one_line, :menu_only
        self.index = :none
        @flow = :inline
      end
    end

    #
    # This method returns all possible options for auto-completion, based
    # on the settings of _index_ and _select_by_.
    #
    def options
      case @select_by
      when :index
        map_items_by_index
      when :name
        map_items_by_name
      else
        map_items_by_index + map_items_by_name
      end
    end

    def map_items_by_index
      if [:letter, :capital_letter].include?(@index)
        # @ and ` are the previous ASCII characters to A and a respectively
        prev_char = (@index == :capital_letter ? '@' : '`')
        all_items.map { prev_char.succ!.dup }
      else
        (1..all_items.size).map(&:to_s)
      end
    end

    def map_items_by_name
      all_items.map(&:name)
    end

    def all_items
      @items + @hidden_items
    end

    #
    # This method processes the auto-completed user selection, based on the
    # rules for this Menu object.  If an action was provided for the
    # selection, it will be executed as described in {#choice}.
    #
    # @param highline_context [HighLine] a HighLine instance to be used
    #   as context.
    # @param selection [String, Integer] index or title of the selected
    #   menu item.
    # @param details additional parameter to be passed when in shell mode.
    # @return [nil, Object] if @nil_on_handled is set it returns +nil+,
    #   else it returns the action return value.
    def select(highline_context, selection, details = nil)
      # add in any hidden menu commands
      items = all_items

      # Find the selected action.
      selected_item = find_item_from_selection(items, selection)

      # Run or return it.
      @highline = highline_context
      value_for_selected_item(selected_item, details)
    end

    def find_item_from_selection(items, selection)
      if selection =~ /^\d+$/ # is a number?
        get_item_by_number(items, selection)
      else
        get_item_by_letter(items, selection)
      end
    end

    # Returns the menu item referenced by its index
    # @param selection [Integer] menu item's index.
    def get_item_by_number(items, selection)
      items[selection.to_i - 1]
    end

    # Returns the menu item referenced by its title/header/name.
    # @param selection [String] menu's title/header/name
    def get_item_by_letter(items, selection)
      item = items.find { |i| i.name == selection }
      return item if item

      # 97 is the "a" letter at ascii table
      # Ex: For "a" it will return 0, and for "c" it will return 2
      index = selection.downcase.ord - 97
      items[index]
    end

    def value_for_selected_item(item, details)
      if item.action
        result = if @shell
                   item.action.call(item.name, details)
                 else
                   item.action.call(item.name)
                 end
        @nil_on_handled ? nil : result
      else
        item.name
      end
    end

    def gather_selected(highline_context, selections, details = nil)
      @highline = highline_context
      # add in any hidden menu commands
      items = all_items

      if selections.is_a?(Array)
        value_for_array_selections(items, selections, details)
      elsif selections.is_a?(Hash)
        value_for_hash_selections(items, selections, details)
      else
        raise ArgumentError, "selections must be either Array or Hash"
      end
    end

    def value_for_array_selections(items, selections, details)
      # Find the selected items and return values
      selected_items = selections.map do |selection|
        find_item_from_selection(items, selection)
      end
      index = 0
      selected_items.map do |selected_item|
        value = value_for_selected_item(selected_item, self.shell ? details[index] : nil)
        index += 1
        value
      end
    end

    def value_for_hash_selections(items, selections, details)
      # Find the selected items and return in hash form
      index = 0
      selections.each_with_object({}) do |(key, selection), memo|
        selected_item = find_item_from_selection(items, selection)
        value = value_for_selected_item(selected_item, self.shell ? details[index] : nil)
        index += 1
        memo[key] = value
      end
    end

    def decorate_index(index)
      if index_color
        HighLine.color(index, index_color)
      else
        index
      end
    end

    #
    # Allows Menu objects to pass as Arrays, for use with HighLine.list().
    # This method returns all menu items to be displayed, complete with
    # indexes.
    #
    def to_ary
      @items.map.with_index { |item, ix| decorate_item(item.text.to_s, ix) }
    end

    def decorate_item(text, ix)
      decorated, non_decorated = mark_for_decoration(text, ix)
      decorate_index(decorated) + non_decorated
    end

    def mark_for_decoration(text, ix)
      case @index
      when :number
        ["#{ix + 1}#{@index_suffix}", text]
      when :letter, :capital_letter
        first_letter = (@index == :capital_letter ? 'A' : 'a')
        ["#{(first_letter.ord + ix).chr}#{@index_suffix}", text]
      when :none
        [text, ""]
      else
        ["#{index}#{@index_suffix}", text]
      end
    end

    #
    # Allows Menu to behave as a String, just like Question.  Returns the
    # _layout_ to be rendered, which is used by HighLine.say().
    #
    def to_s
      case @layout
      when :list
        %(<%= header ? "#{header}:\n" : '' %>) +
          parse_list +
          show_default_if_any +
          "<%= prompt %>"
      when :one_line
        %(<%= header ? "#{header}:  " : '' %>) +
          "<%= prompt %>" \
          "(" + parse_list + ")" +
          show_default_if_any +
          "<%= prompt[/\s*$/] %>"
      when :menu_only
        parse_list +
          show_default_if_any +
          "<%= prompt %>"
      else
        @layout
      end
    end

    def parse_list
      "<%= list( menu, #{@flow.inspect},
           #{@list_option.inspect} ) %>"
    end

    def show_default_if_any
      default.to_s.empty? ? "" : "(#{default}) "
    end

    #
    # This method will update the intelligent responses to account for
    # Menu specific differences.  Calls the superclass' (Question's)
    # build_responses method, overriding its default arguments to specify
    # 'options' will be used to populate choice lists.
    #
    def update_responses
      build_responses(options)
    end
  end
end
