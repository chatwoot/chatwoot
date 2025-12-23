module Administrate
  class ResourceResolver
    def initialize(controller_path)
      @controller_path = controller_path
    end

    def dashboard_class
      ActiveSupport::Inflector.constantize("#{resource_class_name}Dashboard")
    end

    def namespace
      controller_path.split("/").first.to_sym
    end

    def resource_class
      ActiveSupport::Inflector.constantize(resource_class_name)
    end

    def resource_name
      model_path_parts.map(&:underscore).join("__").to_sym
    end

    def resource_title
      resource_class.model_name.human
    end

    private

    def resource_class_name
      model_path_parts.join("::")
    end

    def model_path_parts
      controller_path_parts.map(&:camelize)
    end

    def controller_path_parts
      path_parts = controller_path.split("/")[1..-1]
      path_parts << path_parts.pop.singularize
    end

    attr_reader :controller_path
  end
end
