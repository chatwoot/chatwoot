if defined?(Zeitwerk)
  Zeitwerk::Loader.eager_load_all
else
  Rails.application.eager_load!
end

require "rails/generators/base"
require "administrate/generator_helpers"
require "administrate/namespace"

module Administrate
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Administrate::GeneratorHelpers
      source_root File.expand_path("../templates", __FILE__)

      class_option(
        :namespace,
        type: :string,
        desc: "Namespace where the admin dashboards will live",
        default: "admin",
      )

      def run_routes_generator
        if dashboard_resources.none?
          call_generator("administrate:routes", "--namespace", namespace)
          Rails.application.reload_routes!
        end
      end

      def create_dashboard_controller
        template(
          "application_controller.rb.erb",
          "app/controllers/#{namespace}/application_controller.rb",
        )
      end

      def run_dashboard_generators
        singular_dashboard_resources.each do |resource|
          call_generator "administrate:dashboard", resource,
            "--namespace", namespace
        end
      end

      def model_check
        if valid_dashboard_models.none?
          puts "WARNING: Add models before installing Administrate."
        end
      end

      private

      def namespace
        options[:namespace]
      end

      def singular_dashboard_resources
        dashboard_resources.map(&:to_s).map(&:singularize)
      end

      def dashboard_resources
        Administrate::Namespace.new(namespace).resources
      end

      def valid_dashboard_models
        database_models - invalid_dashboard_models
      end

      def database_models
        ActiveRecord::Base.descendants.reject(&:abstract_class?)
      end

      def invalid_dashboard_models
        (models_without_tables + namespaced_models + unnamed_constants).uniq
      end

      def models_without_tables
        database_models.reject(&:table_exists?)
      end

      def namespaced_models
        database_models.select { |model| model.to_s.include?("::") }
      end

      def unnamed_constants
        ActiveRecord::Base.descendants.reject { |d| d.name == d.to_s }
      end
    end
  end
end
