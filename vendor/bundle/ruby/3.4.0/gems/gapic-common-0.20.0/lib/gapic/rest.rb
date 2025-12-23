# Copyright 2021 Google LLC
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

##
# Rest GAPIC features are still under development.
#

require "faraday"
require "gapic/call_options"
require "gapic/common/version"
require "gapic/headers"
require "gapic/protobuf"
require "gapic/rest/client_stub"
require "gapic/rest/error"
require "gapic/rest/faraday_middleware"
require "gapic/rest/grpc_transcoder"
require "gapic/rest/operation"
require "gapic/rest/paged_enumerable"
require "gapic/rest/server_stream"
require "gapic/rest/threaded_enumerator"
require "gapic/rest/transport_operation"
require "json"
