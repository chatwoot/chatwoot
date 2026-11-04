require 'rails_helper'

RSpec.describe CopilotMessage do
  it 'saves an answer with the chart data its markers name' do
    thread = create(:captain_copilot_thread)
    message = thread.copilot_messages.create!(message_type: :assistant,
                                              message: { 'content' => '[copilot-chart:7]', 'charts' => { '7' => { 'title' => 'Conversations' } } })

    expect(message.reload.message['charts']).to eq('7' => { 'title' => 'Conversations' })
  end
end
