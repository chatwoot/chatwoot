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

require 'elastic_apm/naively_hashable'

module ElasticAPM
  class Stacktrace
    # @api private
    class Frame
      include NaivelyHashable

      attr_accessor(
        :abs_path,
        :filename,
        :function,
        :vars,
        :pre_context,
        :context_line,
        :post_context,
        :library_frame,
        :lineno,
        :module,
        :colno
      )

      def build_context(context_line_count)
        return unless abs_path && context_line_count > 0

        padding = (context_line_count - 1) / 2
        from = lineno - padding - 1
        from = 0 if from < 0
        to = lineno + padding - 1
        file_lines = read_lines(abs_path, from..to)

        return unless file_lines

        self.context_line = file_lines[padding]
        self.pre_context  = file_lines.first(padding)
        self.post_context = file_lines.last(padding)
      end

      private

      def read_lines(path, range)
        File.readlines(path)[range]
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
