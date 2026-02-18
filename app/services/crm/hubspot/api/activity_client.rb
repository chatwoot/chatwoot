# frozen_string_literal: true

module Crm
  module Hubspot
    module Api
      class ActivityClient < Crm::Hubspot::BaseClient
        def create_task(task_data)
          request(:post, '/crm/v3/objects/tasks', body: task_data.to_json)
        end

        def create_meeting(meeting_data)
          request(:post, '/crm/v3/objects/meetings', body: meeting_data.to_json)
        end

        def create_deal(deal_data)
          request(:post, '/crm/v3/objects/deals', body: deal_data.to_json)
        end

        def create_note(note_data)
          request(:post, '/crm/v3/objects/notes', body: note_data.to_json)
        end
      end
    end
  end
end
