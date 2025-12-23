# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module Annotation
      class AnnotationBuilder
        class Annotation < Components::Base
          attr_reader :version, :table_name, :table_comment, :max_size, :database_name

          def initialize(options, **input)
            @options = options

            @version = input[:version]
            @table_name = input[:table_name]
            @table_comment = input[:table_comment]
            @max_size = input[:max_size]
            @model = input[:model]
            @database_name = input[:database_name]
          end

          def body
            [
              MainHeader.new(version, @options[:include_version]),
              SchemaHeader.new(table_name, table_comment, database_name, @options),
              MarkdownHeader.new(max_size),
              *columns,
              IndexAnnotation::AnnotationBuilder.new(@model, @options).build,
              ForeignKeyAnnotation::AnnotationBuilder.new(@model, @options).build,
              CheckConstraintAnnotation::AnnotationBuilder.new(@model, @options).build,
              SchemaFooter.new
            ]
          end

          def build
            components = body.flatten

            if @options[:format_rdoc]
              components.map(&:to_rdoc).compact.join("\n")
            elsif @options[:format_yard]
              components.map(&:to_yard).compact.join("\n")
            elsif @options[:format_markdown]
              components.map(&:to_markdown).compact.join("\n")
            else
              components.map(&:to_default).compact.join("\n")
            end
          end

          private

          def columns
            @model.columns.map do |col|
              _component = ColumnAnnotation::AnnotationBuilder.new(col, @model, max_size, @options).build
            end
          end
        end

        def initialize(klass, options)
          @model = ModelWrapper.new(klass, options)
          @options = options
        end

        def build
          version = @model.migration_version
          table_name = @model.table_name
          table_comment = @model.connection.try(:table_comment, @model.table_name)
          max_size = @model.max_schema_info_width
          database_name = @model.database_name if multi_db_environment?

          _annotation = Annotation.new(@options,
            version: version, table_name: table_name, table_comment: table_comment,
            max_size: max_size, model: @model, database_name: database_name).build
        end

        private

        def multi_db_environment?
          if defined?(::Rails) && ::Rails.env
            ActiveRecord::Base.configurations.configs_for(env_name: ::Rails.env).size > 1
          else
            false
          end
        end
      end
    end
  end
end
