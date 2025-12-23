# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'representable/json'
require 'representable/json/hash'
require 'base64'
require 'date'

module Google
  module Apis
    module Core
      # Support for serializing hashes + property value/nil/unset tracking
      # To be included in representers as a feature.
      # @private
      module JsonRepresentationSupport
        def self.included(base)
          base.extend(JsonSupport)
        end

        # @private
        module JsonSupport
          # Returns a customized getter function for Representable. Allows
          # indifferent hash/attribute access.
          #
          # @param [String] name Property name
          # @return [Proc]
          def getter_fn(name)
            ivar_name = "@#{name}".to_sym
            lambda do |_|
              if respond_to?(:fetch)
                fetch(name, instance_variable_get(ivar_name))
              else
                instance_variable_get(ivar_name)
              end
            end
          end

          # Returns a customized function for Representable that checks whether or not
          # an attribute should be serialized. Allows proper patch semantics by distinguishing
          # between nil & unset values
          #
          # @param [String] name Property name
          # @return [Proc]
          def if_fn(name)
            ivar_name = "@#{name}".to_sym
            lambda do |opts|
              if opts[:user_options] && opts[:user_options][:skip_undefined]
                if respond_to?(:key?)
                  self.key?(name) || instance_variable_defined?(ivar_name)
                else
                  instance_variable_defined?(ivar_name)
                end
              else
                true
              end
            end
          end

          def set_default_options(name, options)
            if options[:base64]
              options[:render_filter] = ->(value, _doc, *_args) { value.nil? ? nil : Base64.urlsafe_encode64(value) }
              options[:parse_filter] = ->(fragment, _doc, *_args) { Base64.urlsafe_decode64(fragment) }
            end
            if options[:numeric_string]
              options[:render_filter] = ->(value, _doc, *_args) { value.nil? ? nil : value.to_s}
              options[:parse_filter] = ->(fragment, _doc, *_args) { fragment.to_i }
            end
            if options[:type] == DateTime
              options[:render_filter] = ->(value, _doc, *_args) { value.nil? ? nil : value.is_a?(DateTime) ? value.rfc3339(3) : value.to_s }
              options[:parse_filter] = ->(fragment, _doc, *_args) { DateTime.parse(fragment) }
            end
            if options[:type] == Date
              options[:render_filter] = ->(value, _doc, *_args) { value.nil? ? nil : value.to_s}
              options[:parse_filter] = ->(fragment, _doc, *_args) { Date.parse(fragment) }
            end

            options[:render_nil] = true
            options[:getter] = getter_fn(name)
            options[:if] = if_fn(name)
          end

          # Define a single value property
          #
          # @param [String] name
          #  Property name
          # @param [Hash] options
          def property(name, options = {})
            set_default_options(name, options)
            super(name, options)
          end

          # Define a collection property
          #
          # @param [String] name
          #  Property name
          # @param [Hash] options
          def collection(name, options = {})
            set_default_options(name, options)
            super(name, options)
          end

          # Define a hash property
          #
          # @param [String] name
          #  Property name
          # @param [Hash] options
          def hash(name = nil, options = nil)
            return super() unless name # Allow Object.hash
            set_default_options(name, options)
            super(name, options)
          end
        end
      end

      # Base decorator for JSON representers
      #
      # @see https://github.com/apotonick/representable
      class JsonRepresentation < Representable::Decorator
        include Representable::JSON
        feature JsonRepresentationSupport
      end

      module JsonObjectSupport
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def from_json(json)
            representation = self.const_get(:Representation)
            representation.new(self.new).from_json(json, unwrap: self)
          end
        end

        def to_json(*a)
          representation = self.class.const_get(:Representation)
          representation.new(self).to_hash(user_options: { skip_undefined: true }).to_json(*a)
        end
      end
    end
  end
end
