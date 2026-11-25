# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'api/v1/conversations/partials/_conversation.json.jbuilder' do
  # The REST payload and the event emitted by the same save have to name the same version of the
  # row, and Postgres keeps microseconds while the record that was just saved may keep nanoseconds.
  it 'renders the updated_at the database stores, not the sub-microsecond clock of the record in memory' do
    conversation = create(:conversation)
    conversation.update!(updated_at: Time.zone.at(1_791_823_361, 121_236_812, :nsec))

    rendered = ApplicationController.render(
      partial: 'api/v1/conversations/partials/conversation', formats: [:json], locals: { conversation: conversation }
    )

    stored = Conversation.find(conversation.id).updated_at.to_f
    expect(JSON.parse(rendered)['updated_at']).to eq(stored)
  end
end
