require_relative "deferred"
require "active_support/core_ext/string/inflections"

module Administrate
  module Field
    class Base
      def self.with_options(options = {})
        Deferred.new(self, options)
      end

      def self.html_class
        field_type.dasherize
      end

      def self.associative?
        self < Associative
      end

      def self.eager_load?
        false
      end

      def self.searchable?
        false
      end

      def self.field_type
        to_s.split("::").last.underscore
      end

      def self.permitted_attribute(attr, _options = nil)
        attr
      end

      def initialize(attribute, data, page, options = {})
        @attribute = attribute
        @data = data
        @page = page
        @resource = options.delete(:resource)
        @options = options
      end

      def html_class
        self.class.html_class
      end

      def name
        attribute.to_s
      end

      def to_partial_path
        "/fields/#{self.class.field_type}/#{page}"
      end

      def required?
        return false unless resource.class.respond_to?(:validators_on)

        resource.class.validators_on(attribute).any? do |v|
          next false unless v.class == ActiveRecord::Validations::PresenceValidator

          options = v.options
          next false if options.include?(:if)
          next false if options.include?(:unless)

          if on_option = options[:on]
            if on_option == :create && !resource.persisted?
              next true
            end

            if on_option == :update && resource.persisted?
              next true
            end

            next false
          end

          true
        end
      end

      attr_reader :attribute, :data, :options, :page, :resource
    end
  end
end
