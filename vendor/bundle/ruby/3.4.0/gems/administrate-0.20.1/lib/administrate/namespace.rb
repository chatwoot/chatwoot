module Administrate
  class Namespace
    def initialize(namespace)
      @namespace = namespace.to_sym
    end

    def resources
      @resources ||= routes.map(&:first).uniq.map do |path|
        Resource.new(namespace, path)
      end
    end

    def routes
      @routes ||= all_routes.select do |controller, _action|
        controller.starts_with?("#{namespace}/")
      end.map do |controller, action|
        [controller.gsub(/^#{namespace}\//, ""), action]
      end
    end

    def resources_with_index_route
      routes.select { |_resource, route| route == "index" }.map(&:first).uniq
    end

    private

    attr_reader :namespace

    def all_routes
      Rails.application.routes.routes.map do |route|
        route.defaults.values_at(:controller, :action).map(&:to_s)
      end
    end
  end
end
