# encoding: utf-8

class HighLine
  class Menu < Question
    # Represents an Item of a HighLine::Menu.
    #
    class Item
      attr_reader :name, :text, :help, :action

      #
      # @param name [String] The name that is matched against the user input
      # @param attributes [Hash] options Hash to tailor menu item to your needs
      # @option attributes text: [String] The text that displays for that
      #   choice (defaults to name)
      # @option attributes help: [String] help/hint string to be displayed.
      # @option attributes action: [Block] a block that gets called when choice
      #   is selected
      #
      def initialize(name, attributes)
        @name = name
        @text = attributes[:text] || @name
        @help = attributes[:help]
        @action = attributes[:action]
      end

      def item_help
        return {} unless help
        { name.to_s.downcase => help }
      end
    end
  end
end
