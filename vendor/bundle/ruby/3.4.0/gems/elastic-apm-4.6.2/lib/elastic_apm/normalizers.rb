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

module ElasticAPM # :nodoc:
  # @api private
  module Normalizers
    # @api privagte
    class Normalizer
      def initialize(config)
        @config = config
      end

      def self.register(name)
        Normalizers.register(name, self)
      end

      def backtrace(payload); end
    end

    def self.register(name, klass)
      @registered ||= {}
      @registered[name] = klass
    end

    def self.build(config)
      normalizers = @registered.transform_values do |klass|
        klass.new(config)
      end

      Collection.new(normalizers)
    end

    # @api private
    class Collection
      # @api private
      class SkipNormalizer
        def initialize; end

        def normalize(*_args)
          :skip
        end
      end

      def initialize(normalizers)
        @normalizers = normalizers
        @default = SkipNormalizer.new
      end

      def for(name)
        @normalizers.fetch(name) { @default }
      end

      def keys
        @normalizers.keys
      end

      def normalize(transaction, name, payload)
        self.for(name).normalize(transaction, name, payload)
      end

      def backtrace(name, payload)
        self.for(name).backtrace(payload)
      end
    end
  end
end
