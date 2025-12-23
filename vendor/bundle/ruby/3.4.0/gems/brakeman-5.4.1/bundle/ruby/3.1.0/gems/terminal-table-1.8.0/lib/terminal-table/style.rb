module Terminal
  class Table
    # A Style object holds all the formatting information for a Table object
    #
    # To create a table with a certain style, use either the constructor
    # option <tt>:style</tt>, the Table#style object or the Table#style= method
    #
    # All these examples have the same effect:
    #
    #     # by constructor
    #     @table = Table.new(:style => {:padding_left => 2, :width => 40})
    #
    #     # by object
    #     @table.style.padding_left = 2
    #     @table.style.width = 40
    #
    #     # by method
    #     @table.style = {:padding_left => 2, :width => 40}
    #
    # To set a default style for all tables created afterwards use Style.defaults=
    #
    #     Terminal::Table::Style.defaults = {:width => 80}
    #
    class Style
      @@defaults = {
        :border_x => "-", :border_y => "|", :border_i => "+",
        :border_top => true, :border_bottom => true,
        :padding_left => 1, :padding_right => 1,
        :margin_left => '',
        :width => nil, :alignment => nil,
        :all_separators => false
      }

      attr_accessor :border_x
      attr_accessor :border_y
      attr_accessor :border_i
      attr_accessor :border_top
      attr_accessor :border_bottom

      attr_accessor :padding_left
      attr_accessor :padding_right

      attr_accessor :margin_left

      attr_accessor :width
      attr_accessor :alignment

      attr_accessor :all_separators


      def initialize options = {}
        apply self.class.defaults.merge(options)
      end

      def apply options
        options.each { |m, v| __send__ "#{m}=", v }
      end

      class << self
        def defaults
          @@defaults
        end

        def defaults= options
          @@defaults = defaults.merge(options)
        end
      end

      def on_change attr
        method_name = :"#{attr}="
        old_method = method method_name
        define_singleton_method(method_name) do |value|
          old_method.call value
          yield attr.to_sym, value
        end
      end
    end
  end
end
