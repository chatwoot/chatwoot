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

require "grpc/errors"
require "grpc/core/status_codes"

require "gapic/common/error"
require "gapic/call_options"
require "gapic/headers"
require "gapic/operation"
require "gapic/paged_enumerable"
require "gapic/protobuf"
require "gapic/stream_input"
require "gapic/common/version"

# Gapic is Google's API client generator
module Gapic
  # The gapic-common gem includes various common libraries for clients built
  # with Gapic.
  module Common
  end
end
