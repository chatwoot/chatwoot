# frozen_string_literal: true

# == Schema Information
#
# Table name: inbox_members
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inbox_id   :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_inbox_members_on_inbox_id              (inbox_id)
#  index_inbox_members_on_inbox_id_and_user_id  (inbox_id,user_id) UNIQUE
#
require 'rails_helper'

RSpec.describe InboxMember do
  include ActiveJob::TestHelper

  describe '#DestroyAssociationAsyncJob' do
    let(:inbox_member) { create(:inbox_member) }

    # ref: https://github.com/chatwoot/chatwoot/issues/4616
    context 'when parent inbox is destroyed' do
      it 'enques and processes DestroyAssociationAsyncJob' do
        perform_enqueued_jobs do
          inbox_member.inbox.destroy!
        end
        expect { inbox_member.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
