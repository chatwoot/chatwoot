# Copyright 2018 Google LLC
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


module Google
  module Cloud
    module Storage
      ##
      # @private
      #
      # Internal conversion of raw data values to/from Storage values
      module Convert
        # @param [String,Symbol,Array<String,Symbol>] str
        def storage_class_for str
          return nil if str.nil?
          return str.map { |s| storage_class_for s } if str.is_a? Array
          { "archive" => "ARCHIVE",
            "coldline" => "COLDLINE",
            "dra" => "DURABLE_REDUCED_AVAILABILITY",
            "durable" => "DURABLE_REDUCED_AVAILABILITY",
            "durable_reduced_availability" => "DURABLE_REDUCED_AVAILABILITY",
            "multi_regional" => "MULTI_REGIONAL",
            "nearline" => "NEARLINE",
            "regional" => "REGIONAL",
            "standard" => "STANDARD" }[str.to_s.downcase] || str.to_s
        end
      end
    end
  end
end
