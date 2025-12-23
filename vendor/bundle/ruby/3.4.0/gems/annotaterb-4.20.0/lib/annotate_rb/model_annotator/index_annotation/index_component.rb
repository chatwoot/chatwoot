# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module IndexAnnotation
      class IndexComponent < Components::Base
        attr_reader :index, :max_size, :options

        def initialize(index, max_size, options)
          @index = index
          @max_size = max_size
          @options = options
        end

        def to_default
          unique_info = index.unique ? " UNIQUE" : ""

          nulls_not_distinct_info = if index.try(:nulls_not_distinct)
            " NULLS NOT DISTINCT"
          else
            ""
          end

          value = index.try(:where).try(:to_s)
          where_info = if value.present?
            " WHERE #{value}"
          else
            ""
          end

          value = index.try(:using).try(:to_sym)
          using_info = if value.present? && value != :btree
            " USING #{value}"
          else
            ""
          end

          include_info = ""
          if options[:show_indexes_include]
            value = index.try(:include)
            include_info = if value.present? && value.any?
              " INCLUDE (#{value.join(",")})"
            else
              ""
            end
          end

          # standard:disable Lint/FormatParameterMismatch
          sprintf(
            "#  %-#{max_size}.#{max_size}s %s%s%s%s%s%s",
            index.name,
            "(#{columns_info.join(",")})",
            include_info,
            unique_info,
            nulls_not_distinct_info,
            where_info,
            using_info
          ).rstrip
          # standard:enable Lint/FormatParameterMismatch
        end

        def to_markdown
          unique_info = index.unique ? " _unique_" : ""

          nulls_not_distinct_info = if index.try(:nulls_not_distinct)
            " _nulls_not_distinct_"
          else
            ""
          end

          value = index.try(:where).try(:to_s)
          where_info = if value.present?
            " _where_ #{value}"
          else
            ""
          end

          value = index.try(:using).try(:to_sym)
          using_info = if value.present? && value != :btree
            " _using_ #{value}"
          else
            ""
          end

          include_info = ""
          if options[:show_indexes_include]
            value = index.try(:include)
            include_info = if value.present? && value.any?
              " _include_ (#{value.join(",")})"
            else
              ""
            end
          end

          details = sprintf(
            "%s%s%s%s%s",
            include_info,
            unique_info,
            nulls_not_distinct_info,
            where_info,
            using_info
          ).strip
          details = " (#{details})" unless details.blank?

          sprintf(
            "# * `%s`%s:\n#     * **`%s`**",
            index.name,
            details,
            columns_info.join("`**\n#     * **`")
          )
        end

        private

        def columns_info
          Array(index.columns).map do |col|
            if index.try(:orders) && index.orders[col.to_s]
              "#{col} #{index.orders[col.to_s].upcase}"
            else
              col.to_s.gsub("\r", '\r').gsub("\n", '\n')
            end
          end
        end
      end
    end
  end
end
