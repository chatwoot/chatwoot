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
  class Context
    # @api private
    class User
      def initialize(id: nil, email: nil, username: nil)
        @id = id
        @email = email
        @username = username
      end

      def self.infer(config, record)
        return unless record

        new(
          id: safe_get(record, config.current_user_id_method)&.to_s,
          email: safe_get(record, config.current_user_email_method),
          username: safe_get(record, config.current_user_username_method)
        )
      end

      attr_accessor :id, :email, :username

      def empty?
        !id && !email && !username
      end

      def any?
        !empty?
      end

      class << self
        private

        def safe_get(record, method_name)
          record.respond_to?(method_name) ? record.send(method_name) : nil
        end
      end
    end
  end
end
