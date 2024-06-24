# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxTeam do
  include ActiveJob::TestHelper

  describe '#DestroyAssociationAsyncJob' do
    let(:inbox_team) { create(:inbox_team) }

    context 'when parent inbox is destroyed' do
      it 'enques and processes DestroyAssociationAsyncJob' do
        perform_enqueued_jobs do
          inbox_team.inbox.destroy!
        end
        expect { inbox_team.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
