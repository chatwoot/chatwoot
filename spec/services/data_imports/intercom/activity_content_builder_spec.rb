require 'rails_helper'

event_content = {
  'assignment' => 'Avery assigned the conversation to Support',
  'assign_and_reopen' => 'Avery assigned the conversation to Support and reopened it',
  'open' => 'Avery opened the conversation',
  'close' => 'Avery closed the conversation',
  'snoozed' => 'Avery snoozed the conversation',
  'participant_added' => 'Avery added Support as a participant',
  'participant_removed' => 'Avery removed Support as a participant',
  'conversation_attribute_updated_by_admin' => 'Avery updated conversation attributes',
  'conversation_attribute_updated_by_user' => 'Avery updated conversation attributes',
  'conversation_attribute_updated_by_workflow' => 'Avery updated conversation attributes',
  'ticket_attribute_updated_by_admin' => 'Avery updated ticket attributes',
  'ticket_state_updated_by_admin' => 'Avery updated the ticket state',
  'custom_action_started' => 'Avery started a custom action',
  'custom_action_finished' => 'Avery finished a custom action',
  'quick_reply' => 'Avery used a quick reply'
}.freeze

RSpec.describe DataImports::Intercom::ActivityContentBuilder do
  event_content.each do |part_type, expected_content|
    it "builds readable content for #{part_type}" do
      part = {
        'part_type' => part_type,
        'author' => { 'type' => 'admin', 'name' => 'Avery' },
        'assigned_to' => { 'name' => 'Support' }
      }

      expect(described_class.new(part).perform).to eq(expected_content)
    end
  end

  it 'uses a humanized fallback for unknown future event types' do
    part = { 'part_type' => 'journey_stage_changed', 'author' => { 'type' => 'bot' } }

    expect(described_class.new(part).perform).to eq('Intercom automation recorded journey stage changed')
  end

  it 'appends sanitized body context' do
    part = {
      'part_type' => 'close',
      'author' => { 'type' => 'admin' },
      'body' => '<p>Customer confirmed <strong>resolution</strong></p><script>alert(1)</script>'
    }

    expect(described_class.new(part).perform).to eq(
      'Intercom teammate closed the conversation: Customer confirmed resolution'
    )
  end
end
