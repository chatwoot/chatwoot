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
  # @api private
  module SpanHelpers
    # @api private
    module ClassMethods
      def span_class_method(method, name = nil, type = nil)
        __span_method_on(singleton_class, method, name, type)
      end

      def span_method(method, name = nil, type = nil)
        __span_method_on(self, method, name, type)
      end

      private

      def __span_method_on(klass, method, name = nil, type = nil)
        name ||= method.to_s
        type ||= Span::DEFAULT_TYPE

        klass.prepend(Module.new do
          ruby2_keywords(define_method(method) do |*args, &block|
            unless ElasticAPM.current_transaction
              return super(*args, &block)
            end

            ElasticAPM.with_span name.to_s, type.to_s do
              super(*args, &block)
            end
          end)
        end)
      end
    end

    def self.included(kls)
      kls.class_eval do
        extend ClassMethods
      end
    end
  end
end
