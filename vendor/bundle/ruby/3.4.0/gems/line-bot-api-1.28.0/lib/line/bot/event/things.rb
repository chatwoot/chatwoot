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
      module ThingsType
        Link = 'link'
        Unlink = 'unlink'
        ScenarioResult = 'scenarioResult'
        Unsupport = 'unsupport'
      end

      # LINE Things API related events.
      #
      # * https://developers.line.biz/en/reference/messaging-api/#device-link-event
      # * https://developers.line.biz/en/reference/messaging-api/#device-unlink-event
      # * https://developers.line.biz/en/reference/messaging-api/#scenario-result-event
      class Things < Base
        def type
          ThingsType.const_get(Util.camelize(@src['things']['type']))
        rescue NameError
          ThingsType::Unsupport
        end

        def device_id
          @src['things']['deviceId']
        end
      end
    end
  end
end
