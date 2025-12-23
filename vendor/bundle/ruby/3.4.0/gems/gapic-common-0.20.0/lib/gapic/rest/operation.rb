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

require "gapic/generic_lro/base_operation"

module Gapic
  module Rest
    ##
    # This alias is left here for the backwards compatibility purposes.
    # Rest LROs now use the same GenericLRO base as the GRPC LROs.
    # @deprecated Use {Gapic::GenericLRO::BaseOperation} instead.
    BaseOperation = Gapic::GenericLRO::BaseOperation
  end
end
