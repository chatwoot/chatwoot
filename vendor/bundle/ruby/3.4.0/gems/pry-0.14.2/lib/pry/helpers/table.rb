# frozen_string_literal: true

class Pry
  module Helpers
    def self.tablify_or_one_line(heading, things, pry_instance = Pry.new)
      plain_heading = Pry::Helpers::Text.strip_color(heading)
      attempt = Table.new(things, column_count: things.size)
      if attempt.fits_on_line?(pry_instance.output.width - plain_heading.size - 2)
        "#{heading}: #{attempt}\n"
      else
        content = tablify_to_screen_width(things, { indent: '  ' }, pry_instance)
        "#{heading}: \n#{content}\n"
      end
    end

    def self.tablify_to_screen_width(things, options, pry_instance = Pry.new)
      options ||= {}
      things = things.compact
      if (indent = options[:indent])
        usable_width = pry_instance.output.width - indent.size
        tablify(things, usable_width, pry_instance).to_s.gsub(/^/, indent)
      else
        tablify(things, pry_instance.output.width, pry_instance).to_s
      end
    end

    def self.tablify(things, line_length, pry_instance = Pry.new)
      table = Table.new(things, { column_count: things.size }, pry_instance)
      until (table.column_count == 1) || table.fits_on_line?(line_length)
        table.column_count -= 1
      end
      table
    end

    class Table
      attr_reader :items, :column_count
      def initialize(items, args, pry_instance = Pry.new)
        @column_count = args[:column_count]
        @config = pry_instance.config
        self.items = items
      end

      def to_s
        rows_to_s.join("\n")
      end

      def rows_to_s(style = :color_on)
        widths = columns.map { |e| _max_width(e) }
        @rows_without_colors.map do |r|
          padded = []
          r.each_with_index do |e, i|
            next unless e

            item = e.ljust(widths[i])
            item.sub! e, _recall_color_for(e) if style == :color_on
            padded << item
          end
          padded.join(@config.ls.separator)
        end
      end

      def items=(items)
        @items = items
        _rebuild_colorless_cache
        _recolumn
      end

      def column_count=(count)
        @column_count = count
        _recolumn
      end

      def fits_on_line?(line_length)
        _max_width(rows_to_s(:no_color)) <= line_length
      end

      def columns
        @rows_without_colors.transpose
      end

      def ==(other)
        items == other.to_a
      end

      def to_a
        items.to_a
      end

      private

      def _max_width(things)
        things.compact.map(&:size).max || 0
      end

      def _rebuild_colorless_cache
        @colorless_cache = {}
        @plain_items = []
        items.map do |e|
          plain = Pry::Helpers::Text.strip_color(e)
          @colorless_cache[plain] = e
          @plain_items << plain
        end
      end

      def _recolumn
        @rows_without_colors = []
        return if items.size.zero?

        row_count = (items.size.to_f / column_count).ceil
        row_count.times do |i|
          row_indices = (0...column_count).map { |e| row_count * e + i }
          @rows_without_colors << row_indices.map { |e| @plain_items[e] }
        end
      end

      def _recall_color_for(thing)
        @colorless_cache[thing]
      end
    end
  end
end
