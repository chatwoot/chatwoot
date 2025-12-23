if defined?(Zeitwerk)
  Zeitwerk::Loader.eager_load_all
else
  Rails.application.eager_load!
end

require "rails/generators/base"
require "administrate/generator_helpers"
require "administrate/namespace"
require "generators/administrate/test_record"

module Administrate
  module Generators
    class RoutesGenerator < Rails::Generators::Base
      include Administrate::GeneratorHelpers
      source_root File.expand_path("../templates", __FILE__)
      class_option(
        :namespace,
        type: :string,
        desc: "Namespace where the admin dashboards live",
        default: "admin",
      )

      def insert_dashboard_routes
        if valid_dashboard_models.any?
          route(dashboard_routes)
        end
      end

      def warn_about_invalid_models
        invalid_dashboard_models.each do |model|
          puts "WARNING: Unable to generate a dashboard for #{model}."
          if namespaced_models.include?(model)
            puts "       - Administrate does not yet support namespaced models."
          end
          if models_without_tables.include?(model)
            puts "       - It is not connected to a database table."
            puts "         Make sure your database migrations are up to date."
          end
        end

        unnamed_constants.each do |invalid_model|
          puts "NOTICE: Skipping dynamically generated model #{invalid_model}."
        end
      end

      private

      def namespace
        options[:namespace]
      end

      def dashboard_resources
        valid_dashboard_models.map do |model|
          model.to_s.pluralize.underscore
        end
      end

      def valid_dashboard_models
        database_models - invalid_dashboard_models
      end

      def database_models
        ActiveRecord::Base.descendants.
          reject(&:abstract_class?).
          reject { |k| k < Administrate::Generators::TestRecord }.
          sort_by(&:to_s)
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

      def dashboard_routes
        ERB.new(File.read(routes_file_path)).result(binding)
      end

      def routes_file_path
        File.expand_path(find_in_source_paths("routes.rb.erb"))
      end
    end
  end
end
