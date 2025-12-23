# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "grpc"
require "grpc/errors"
require "grpc/google_rpc_status_utils"
require "google/protobuf/well_known_types"
# Required in order to deserialize common error detail proto types
require "google/rpc/error_details_pb"

module GRPC
  class BadStatus < StandardError
    def status_details
      rpc_status = to_rpc_status

      return nil.to_a if rpc_status.nil?

      rpc_status.details.map do |detail|
        detail_type = Google::Protobuf::DescriptorPool.generated_pool.lookup detail.type_name
        detail = detail.unpack detail_type.msgclass if detail_type
        detail
      rescue Google::Protobuf::ParseError
        detail
      end
    end
  end
end
