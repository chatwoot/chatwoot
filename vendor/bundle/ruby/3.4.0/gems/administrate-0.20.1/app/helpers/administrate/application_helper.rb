module Administrate
  module ApplicationHelper
    PLURAL_MANY_COUNT = 2.1
    SINGULAR_COUNT = 1

    def application_title
      Rails.application.class.module_parent_name.titlecase
    end

    def render_field(field, locals = {})
      locals[:field] = field
      render locals: locals, partial: field.to_partial_path
    end

    def requireness(field)
      field.required? ? "required" : "optional"
    end

    def dashboard_from_resource(resource_name)
      "#{resource_name.to_s.singularize}_dashboard".classify.constantize
    end

    def model_from_resource(resource_name)
      dashboard = dashboard_from_resource(resource_name)
      dashboard.try(:model) || resource_name.to_sym
    end

    # Unification of
    # {Administrate::ApplicationController#existing_action? existing_action?}
    # and
    # {Administrate::ApplicationController#authorized_action?
    # authorized_action?}
    #
    # @param target [ActiveRecord::Base, Class, Symbol, String] A resource,
    #   a class of resources, or the name of a class of resources.
    # @param action_name [String, Symbol] The name of an action that might be
    #   possible to perform on a resource or resource class.
    # @return [Boolean] Whether the action both (a) exists for the record class,
    #   and (b) the current user is authorized to perform it on the record
    #   instance or class.
    def accessible_action?(target, action_name)
      target = target.to_sym if target.is_a?(String)
      target_class_or_class_name =
        target.is_a?(ActiveRecord::Base) ? target.class : target

      existing_action?(target_class_or_class_name, action_name) &&
        authorized_action?(target, action_name)
    end

    def display_resource_name(resource_name, opts = {})
      dashboard_from_resource(resource_name).resource_name(
        count: opts[:singular] ? SINGULAR_COUNT : PLURAL_MANY_COUNT,
        default: default_resource_name(resource_name, opts),
      )
    end

    def sort_order(order)
      case order
      when "asc" then "ascending"
      when "desc" then "descending"
      else "none"
      end
    end

    def resource_index_route(resource_name)
      url_for(
        action: "index",
        controller: "/#{namespace}/#{resource_name}",
      )
    end

    def sanitized_order_params(page, current_field_name)
      collection_names = page.item_associations + [current_field_name]
      association_params = collection_names.map do |assoc_name|
        { assoc_name => %i[order direction page per_page] }
      end
      params.permit(:search, :id, :_page, :per_page, association_params)
    end

    def clear_search_params
      params.except(:search, :_page).permit(
        :per_page, resource_name => %i[order direction]
      )
    end

    private

    def default_resource_name(name, opts = {})
      resource_name = (opts[:singular] ? name.to_s : name.to_s.pluralize)
      resource_name.gsub("/", "_").titleize
    end
  end
end
