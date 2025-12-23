require "administrate/field/belongs_to"
require "administrate/field/boolean"
require "administrate/field/date_time"
require "administrate/field/date"
require "administrate/field/email"
require "administrate/field/has_many"
require "administrate/field/has_one"
require "administrate/field/number"
require "administrate/field/polymorphic"
require "administrate/field/select"
require "administrate/field/string"
require "administrate/field/text"
require "administrate/field/time"
require "administrate/field/url"
require "administrate/field/password"

module Administrate
  class BaseDashboard
    include Administrate

    DASHBOARD_SUFFIX = "Dashboard".freeze

    class << self
      def model
        to_s.chomp(DASHBOARD_SUFFIX).classify.constantize
      end

      def resource_name(opts)
        model.model_name.human(opts)
      end
    end

    def attribute_types
      self.class::ATTRIBUTE_TYPES
    end

    def attribute_type_for(attribute_name)
      attribute_types.fetch(attribute_name) do
        fail attribute_not_found_message(attribute_name)
      end
    end

    def attribute_types_for(attribute_names)
      attribute_names.each_with_object({}) do |name, attributes|
        attributes[name] = attribute_type_for(name)
      end
    end

    def all_attributes
      attribute_types.keys
    end

    def form_attributes(action = nil)
      action =
        case action
        when "update" then "edit"
        when "create" then "new"
        else action
        end
      specific_form_attributes_for(action) || self.class::FORM_ATTRIBUTES
    end

    def specific_form_attributes_for(action)
      return unless action

      cname = "FORM_ATTRIBUTES_#{action.upcase}"

      self.class.const_get(cname) if self.class.const_defined?(cname)
    end

    def permitted_attributes(action = nil)
      attributes = form_attributes action

      if attributes.is_a? Hash
        attributes = attributes.values.flatten
      end

      attributes.map do |attr|
        attribute_types[attr].permitted_attribute(
          attr,
          resource_class: self.class.model,
          action: action,
        )
      end.uniq
    end

    def show_page_attributes
      self.class::SHOW_PAGE_ATTRIBUTES
    end

    def collection_attributes
      if self.class::COLLECTION_ATTRIBUTES.is_a?(Hash)
        self.class::COLLECTION_ATTRIBUTES.values.flatten
      else
        self.class::COLLECTION_ATTRIBUTES
      end
    end

    def search_attributes
      attribute_types.keys.select do |attribute|
        attribute_types[attribute].searchable?
      end
    end

    def display_resource(resource)
      "#{resource.class} ##{resource.id}"
    end

    def collection_includes
      attribute_includes(collection_attributes)
    end

    def item_includes
      # Deprecated, internal usage has moved to #item_associations
      Administrate.warn_of_deprecated_method(self.class, :item_includes)
      attribute_includes(show_page_attributes)
    end

    def item_associations
      attributes = if show_page_attributes.is_a?(Hash)
                     show_page_attributes.values.flatten
                   else
                     show_page_attributes
                   end
      attribute_associated attributes
    end

    private

    def attribute_not_found_message(attr)
      "Attribute #{attr} could not be found in #{self.class}::ATTRIBUTE_TYPES"
    end

    def attribute_includes(attributes)
      attributes.map do |key|
        field = attribute_type_for(key)

        key if field.eager_load?
      end.compact
    end

    def attribute_associated(attributes)
      attributes.map do |key|
        field = attribute_type_for(key)

        key if field.associative?
      end.compact
    end
  end
end
