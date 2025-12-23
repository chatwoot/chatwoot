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

module Line
  module Bot
    module Event
      # Event object for when a user has linked his/her LINE account with a provider's service account.
      #
      # https://developers.line.biz/en/reference/messaging-api/#account-link-event
      class AccountLink < Base
        # @return [String]
        def result
          @src['link']['result']
        end

        # @return [String]
        def nonce
          @src['link']['nonce']
        end
      end
    end
  end
end
