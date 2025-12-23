# Copyright 2016 LINE
#
# LINE Corporation licenses this file to you under the Apache License,
# version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

require 'line/bot/api/version'

module Line
  module Bot
    module API
      DEFAULT_OAUTH_ENDPOINT = "https://api.line.me"
      DEFAULT_ENDPOINT = "https://api.line.me/v2"
      DEFAULT_BLOB_ENDPOINT = "https://api-data.line.me/v2"
      DEFAULT_LIFF_ENDPOINT = "https://api.line.me/liff/v1"

      DEFAULT_HEADERS = {
        'Content-Type' => 'application/json; charset=UTF-8',
        'User-Agent'   => "LINE-BotSDK-Ruby/#{VERSION}"
      }.freeze
    end
  end
end
