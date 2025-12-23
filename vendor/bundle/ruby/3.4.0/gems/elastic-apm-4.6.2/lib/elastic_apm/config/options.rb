# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  class Config
    # @api private
    module Options
      # @api private
      class Option
        def initialize(
          key,
          value: nil,
          type: :string,
          default: nil,
          converter: nil
        )
          @key = key
          @type = type
          @default = default
          @converter = converter

          set(value || default)
        end

        attr_reader :key, :default, :type, :converter
        attr_accessor :value

        def set(value)
          @value = normalize(value)
        end

        def env_key
          "ELASTIC_APM_#{key.upcase}"
        end

        private

        # rubocop:disable Metrics/CyclomaticComplexity
        def normalize(val)
          return if val.nil?

          if @converter
            return @converter.call(val)
          end

          case type
          when :string then val.to_s
          when :int then val.to_i
          when :float then val.to_f
          when :bool then normalize_bool(val)
          when :list then normalize_list(val)
          when :dict then normalize_dict(val)
          when :url then normalize_url(val)
          else
            # raise "Unknown options type '#{type.inspect}'"
            val
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def normalize_bool(val)
          return val unless val.is_a?(String)
          !%w[0 false].include?(val.strip.downcase)
        end

        def normalize_list(val)
          return Array(val) unless val.is_a?(String)
          val.split(/[ ,]/)
        end

        def normalize_dict(val)
          return val unless val.is_a?(String)
          Hash[val.split(/[&,]/).map { |kv| kv.split('=') }]
        end

        def normalize_url(val)
          val = val.to_s
          val.end_with?('/') ? val.chomp('/') : val
        end
      end

      # @api private
      module ClassMethods
        def schema
          @schema ||= {}
        end

        def option(key, **args)
          schema[key] = args
        end
      end

      # @api private
      module InstanceMethods
        def load_schema
          Hash[self.class.schema.map do |key, args|
            [key, Option.new(key, **args)]
          end]
        end

        def method_missing(name, *value)
          name_str = name.to_s

          if name_str.end_with?('=')
            key = name_str[0...-1].to_sym
            set(key, value.first)

          elsif name_str.end_with?('?')
            key = name_str[0...-1].to_sym
            options.key?(key) ? options[key].value : super

          elsif options.key?(name)
            options.fetch(name).value

          else
            super
          end
        end

        def [](key)
          options[key]
        end
        alias :get :[]

        def set(key, value)
          options.fetch(key.to_sym).set(value)
        rescue KeyError
          warn format("Unknown option '%s'", key)
          nil
        end
      end

      def self.extended(kls)
        kls.instance_eval { extend ClassMethods }
        kls.class_eval { include InstanceMethods }
      end
    end
  end
end
