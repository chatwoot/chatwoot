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
  class Error
    # @api private
    class Exception
      MOD_SPLIT = '::'

      def initialize(attrs = nil)
        return unless attrs

        attrs.each do |key, val|
          send(:"#{key}=", val)
        end
      end

      def self.from_exception(exception, **attrs)
        new({
          message: exception.message.to_s,
          type: exception.class.to_s,
          module: format_module(exception),
          cause: exception.cause && Exception.from_exception(exception.cause)
        }.merge(attrs))
      end

      attr_accessor(
        :attributes,
        :code,
        :handled,
        :message,
        :module,
        :stacktrace,
        :type,
        :cause
      )

      def inspect
        '<ElasticAPM::Error::Exception' \
          " type:#{type}" \
          " message:#{message}" \
          '>'
      end

      class << self
        private

        def format_module(exception)
          exception.class.to_s.split(MOD_SPLIT)[0...-1].join(MOD_SPLIT)
        end
      end
    end
  end
end
