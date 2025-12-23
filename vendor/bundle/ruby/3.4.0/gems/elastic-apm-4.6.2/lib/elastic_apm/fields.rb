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
#
# frozen_string_literal: true

module ElasticAPM
  # An interface for creating simple, value holding objects that correspond to
  # object fields in the API.
  #
  # Example:
  #   class MyThing
  #     include Fields
  #     field :name
  #     field :address, default: 'There'
  #   end
  #
  #   MyThing.new(name: 'AJ').to_h
  #     # => { name: 'AJ' }
  #   MyThing.new().empty?
  #     # => true
  module Fields
    class Field
      def initialize(key, default: nil)
        @key = key
        @default = default
      end

      attr_reader :key, :default
    end

    module InstanceMethods
      def initialize(**attrs)
        schema.each do |key, field|
          send(:"#{key}=", field.default)
        end

        attrs.each do |key, value|
          send(:"#{key}=", value)
        end

        super()
      end

      def empty?
        self.class.schema.each do |key, field|
          next if send(key).nil?
          return false
        end

        true
      end

      def to_h
        schema.each_with_object({}) do |(key, field), hsh|
          hsh[key] = send(key)
        end
      end

      private

      def schema
        self.class.schema
      end
    end

    module ClassMethods
      def field(key, default: nil)
        field = Field.new(key, default: default)
        schema[key] = field

        attr_accessor(key)
      end

      attr_reader :schema
    end

    def self.included(cls)
      cls.extend(ClassMethods)
      cls.include(InstanceMethods)

      cls.instance_variable_set(:@schema, {})
    end
  end
end
