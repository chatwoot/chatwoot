require "rails/generators/named_base"

module Administrate
  module Generators
    class DashboardGenerator < Rails::Generators::NamedBase
      ATTRIBUTE_TYPE_MAPPING = {
        boolean: "Field::Boolean",
        date: "Field::Date",
        datetime: "Field::DateTime",
        enum: "Field::Select",
        float: "Field::Number",
        integer: "Field::Number",
        time: "Field::Time",
        text: "Field::Text",
        string: "Field::String",
        uuid: "Field::String",
      }

      ATTRIBUTE_OPTIONS_MAPPING = {
        # procs must be defined in one line!
        enum: {  searchable: false,
                 collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys } },
        float: { decimals: 2 },
      }

      DEFAULT_FIELD_TYPE = "Field::String.with_options(searchable: false)"
      COLLECTION_ATTRIBUTE_LIMIT = 4
      READ_ONLY_ATTRIBUTES = %w[id created_at updated_at]

      class_option(
        :namespace,
        type: :string,
        desc: "Namespace where the admin dashboards live",
        default: "admin",
      )

      source_root File.expand_path("../templates", __FILE__)

      def create_dashboard_definition
        template(
          "dashboard.rb.erb",
          Rails.root.join("app/dashboards/#{file_name}_dashboard.rb"),
        )
      end

      def create_resource_controller
        destination = Rails.root.join(
          "app/controllers/#{namespace}/#{file_name.pluralize}_controller.rb",
        )

        template("controller.rb.erb", destination)
      end

      private

      def namespace
        options[:namespace]
      end

      def attributes
        attrs = (
          klass.reflections.keys +
          klass.columns.map(&:name) -
          redundant_attributes
        )

        primary_key = attrs.delete(klass.primary_key)
        created_at = attrs.delete("created_at")
        updated_at = attrs.delete("updated_at")

        [
          primary_key,
          *attrs.sort,
          created_at,
          updated_at,
        ].compact
      end

      def form_attributes
        attributes - READ_ONLY_ATTRIBUTES
      end

      def redundant_attributes
        klass.reflections.keys.flat_map do |relationship|
          redundant_attributes_for(relationship)
        end.compact
      end

      def redundant_attributes_for(relationship)
        case association_type(relationship)
        when "Field::Polymorphic"
          [relationship + "_id", relationship + "_type"]
        when "Field::BelongsTo"
          relationship + "_id"
        end
      end

      def field_type(attribute)
        type = column_type_for_attribute(attribute.to_s)

        if type
          ATTRIBUTE_TYPE_MAPPING.fetch(type, DEFAULT_FIELD_TYPE) +
            options_string(ATTRIBUTE_OPTIONS_MAPPING.fetch(type, {}))
        else
          association_type(attribute)
        end
      end

      def column_type_for_attribute(attr)
        if enum_column?(attr)
          :enum
        else
          column_types(attr)
        end
      end

      def enum_column?(attr)
        klass.respond_to?(:defined_enums) &&
          klass.defined_enums.keys.include?(attr)
      end

      def column_types(attr)
        klass.columns.find { |column| column.name == attr }.try(:type)
      end

      def association_type(attribute)
        relationship = klass.reflections[attribute.to_s]
        if relationship.has_one?
          "Field::HasOne"
        elsif relationship.collection?
          "Field::HasMany"
        elsif relationship.polymorphic?
          "Field::Polymorphic"
        else
          "Field::BelongsTo"
        end
      end

      def klass
        @klass ||= Object.const_get(class_name)
      end

      def options_string(options)
        if options.any?
          ".with_options(#{inspect_hash_as_ruby(options)})"
        else
          ""
        end
      end

      def inspect_hash_as_ruby(hash)
        hash.map do |key, value|
          v_str = value.respond_to?(:call) ? proc_string(value) : value.inspect
          "#{key}: #{v_str}"
        end.join(", ")
      end

      def proc_string(value)
        source = value.source_location
        proc_string = IO.readlines(source.first)[source.second - 1]
        proc_string[/->[^}]*} | (lambda|proc).*end/x]
      end
    end
  end
end
